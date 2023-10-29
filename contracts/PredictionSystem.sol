pragma solidity ^0.5.0;

import "./StreamerChannel.sol";
import "./Prediction.sol";

contract PredictionSystem {
    StreamerChannel streamerChannelContract;
    address streamerChannelAddress;
    uint256 numPredictions;
    address[] pastPredictions;
    uint256 closedPredictionPayout;

    Prediction currentPrediction;
    address currentPredictionAddress;
    address[] currentParticipants;
    uint256 currentOptions;

    
    mapping(uint256 => mapping(uint256 => uint256)) totalTokensPerOption;
    mapping(uint256 => mapping(address => uint256)) viewerTokensOnOption;
    mapping(uint256 => mapping(address => uint256)) chosenOption; 
    

    // Events
    event NewPrediction(address _currentPrediction);
    event NewClosedPredictionPayout(uint256 _amount);
    event NewParticipant(address _participant, uint256 _option, uint256 _tokens);

    // Modifiers
    modifier validPayout(uint256 payout) {
        require(payout > 0, "New payout must be a positive integer.");
        _;
    }

    modifier predictionActive() {
        require(currentPredictionAddress != address(0), "There is currently no active predictions.");
        _;
    }

    modifier onlyStreamerOrMods() {
        require(streamerChannelContract.isStreamerOrMods(msg.sender), "Only streamers or mods can carry out this function.");
        _;
    }

    modifier onlyCurrentPrediction() {
        require(msg.sender == currentPredictionAddress, "Only the current prediction can call this function.");
        _;
    }

    
    // Default 0 unselected
    modifier validOption(uint256 selectedOption) {
        require(selectedOption <= currentOptions, "Invalid option selected.");
        require(selectedOption > 0, "Invalid option selected.");
        _;
    }

    modifier validPredictionAmount(uint256 predictionAmount) {
        require(predictionAmount > 0, "Prediction amount must be greater than 0");
        require(predictionAmount <= streamerChannelContract.getViewerTokens(tx.origin), "Prediction amount more than tokens possessed.");
        _;
    }

    modifier haveNotPredicted() {
        require(chosenOption[numPredictions][tx.origin] == 0, "User has already made a prediction for this session.");
        _;
    }
    

    // Functions
    constructor(address _streamerChannelContract, uint256 _closedPredictionPayout) public validPayout(_closedPredictionPayout) {
        streamerChannelAddress = _streamerChannelContract;
        streamerChannelContract = StreamerChannel(_streamerChannelContract);
        closedPredictionPayout = _closedPredictionPayout;
    }

    function createPrediction(uint256 options) public onlyStreamerOrMods {
        currentPrediction = new Prediction(options, streamerChannelAddress);
        currentPredictionAddress = address(currentPrediction);
        currentOptions = options;
    }

    function unravelResults(uint256 result) public onlyStreamerOrMods {
        // Calculate total losses
        uint256 totalLosings = 0;
        for (uint256 i = 1; i <= currentOptions; i++) {
            if (i != result) {
                totalLosings += totalTokensPerOption[numPredictions][i];
            }
        }

        // Distribute losings to winners
        uint256 tokensOnWinningOption = totalTokensPerOption[numPredictions][result];
        for (uint256 i = 0; i < currentParticipants.length; i++) {
            address participant = currentParticipants[i];
            if (chosenOption[numPredictions][participant] == result) {
                uint256 participantPredictionAmount = viewerTokensOnOption[numPredictions][participant];
                if (participantPredictionAmount == 0) {
                    streamerChannelContract.issueTokens(participant, closedPredictionPayout);
                } else {
                    // Minimally get back amount spent, if no other participants spent
                    uint256 winnings = participantPredictionAmount + (participantPredictionAmount * totalLosings) / tokensOnWinningOption;
                    streamerChannelContract.issueTokens(participant, winnings);
                }
            }
        }

        // Clean up prediction
        pastPredictions.push(currentPredictionAddress);
        currentPredictionAddress = address(0); // Make predictionActive check fail
        currentOptions = 0; // Make validOption fail
        delete currentParticipants;
        numPredictions += 1; // Move on to next prediction, resets totalTokensPerOption, viewerTokensOnOption and chosenOption mappings
    }

    function setClosedPredictionPayout(uint256 _closedPredictionPayout) public onlyStreamerOrMods {
        closedPredictionPayout = _closedPredictionPayout;
        emit NewClosedPredictionPayout(_closedPredictionPayout);
    }

    function getClosedPredictionPayout() public view returns(uint256) {
        return closedPredictionPayout;
    }

    // Function to be called when participant makes a prediction
    function makePrediction(address newParticipant, uint256 option, uint256 tokens) private haveNotPredicted {
        currentParticipants.push(newParticipant);
        emit NewParticipant(newParticipant, option, tokens);

        // Once prediction made, no changes allowed
        chosenOption[numPredictions][tx.origin] = option;
        if (tokens > 0) {
            streamerChannelContract.spendTokens(tx.origin, tokens);
            viewerTokensOnOption[numPredictions][tx.origin] = tokens;
            totalTokensPerOption[numPredictions][option] += tokens;
        }
    }

    
    // Function to be called by Prediction to make specific prediction
    function betOnOpenOption(uint256 option, uint256 tokens) public onlyCurrentPrediction predictionActive validOption(option) validPredictionAmount(tokens) {
        makePrediction(tx.origin, option, tokens);
    }

    // Function to be called by Prediction to make specific prediction
    function betOnClosedOption(uint256 option) public onlyCurrentPrediction predictionActive validOption(option) {
        makePrediction(tx.origin, option, 0);
    }

    function getCurrentPrediction() public view predictionActive returns(address) {
        return currentPredictionAddress;
    }

    function getViewerPrediction(address viewer) public view predictionActive returns(uint256) {
        return chosenOption[numPredictions][viewer];
    }

    function getViewerPredictionAmount(address viewer) public view predictionActive returns(uint256) {
        return viewerTokensOnOption[numPredictions][viewer];
    }

    function getTotalPredictionAmountForOption(uint256 option) public view predictionActive returns(uint256) {
        return totalTokensPerOption[numPredictions][option];
    }
    
}