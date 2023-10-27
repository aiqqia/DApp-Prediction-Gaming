//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./StreamerChannel.sol"; // Import the StreamChannel interface

contract InteractionSystem{
    StreamerChannel streamerChannelContract;
    address[] donors;
     
    mapping(address => bool) public subscribers;

    struct InteractionType {
        uint256 cost;
        string description;
    }

    InteractionType[] public interactionCosts;

    event InteractionRequested(address requester, uint256 interactionCost, string description);
    event DonorAdded(address donor);
    event SubscriberAdded(address subscriber);
    event AllDonors(address[] donors);

    constructor(address streamChannelAddress) {
        streamerChannelContract = StreamerChannel(streamChannelAddress);
        address streamer = streamerChannelContract.getStreamer();
        require(streamer == msg.sender, "Only Streamer can deploy this contract!");
        
        streamerChannelContract.setInteractionSystemContract(address(this));

        // Initialize interaction costs
        interactionCosts.push(InteractionType(10, "Basic Interaction"));
        interactionCosts.push(InteractionType(20, "Enhanced Interaction"));
        interactionCosts.push(InteractionType(30, "Premium Interaction"));

    }

    modifier onlyStreamer() {
        require(streamerChannelContract.getStreamer() == msg.sender, "Only Streamer can call this function");
        _;
    }

    modifier donationGreaterThanZero(uint256 value) {
        require(value > 0, "Donation cannot be 0 ether!");
        _;
    }

    modifier subscriberNotExists(address viewer) {
        require(!subscribers[viewer], "Subscriber already exists");
        _;
    }

    modifier isEnoughSubscriptionFeeProvided(uint256 value){
        //subscription fee 1 eth
        uint256 subscriptionFee = 1 ether;

        //require msg.value >= 1 eth
        require(msg.value >= subscriptionFee, "Subscription requires at least 1 ether!");
        _;
    }

    modifier isEnoughTokenBalance(address viewer, uint256 interactionCost){
        //require viewer token balance >= interactionCost
        require(streamerChannelContract.getViewerTokens(viewer) >= interactionCost, "Viewer should have enough token balance!");
        _;
    }

    modifier isValidInteractionCost(uint256 cost) {
        bool valid = false;
        for (uint256 i = 0; i < interactionCosts.length; i++) {
            if (interactionCosts[i].cost == cost) {
                valid = true;
                break;
            }
        }
        require(valid, "Invalid interaction cost");
        _;
    }

    function requestInteraction(uint256 interactionCost) public 
        isEnoughTokenBalance(msg.sender, interactionCost) 
        isValidInteractionCost(interactionCost) {
        
        //minus interactionCost from viewer token balance
        streamerChannelContract.spendTokens(msg.sender, interactionCost);

        string memory interactionDescription;
        for (uint256 i = 0; i < interactionCosts.length; i++) {
            if (interactionCosts[i].cost == interactionCost) {
                interactionDescription = interactionCosts[i].description;
            }
        }

        emit InteractionRequested(msg.sender, interactionCost, interactionDescription);
    }

    function makeDonation() public payable donationGreaterThanZero(msg.value){

        address payable streamer = payable (streamerChannelContract.getStreamer());

        //check if alrdy in donors
        for(uint256 i=0; i < donors.length; i++){
            address donor = donors[i];
            if(donor == msg.sender){
                //transfer ether to the streamer
                streamer.transfer(msg.value);
                return;
            }
        }
        //add to donors
        donors.push(msg.sender);

        //transfer ether to the streamer
        streamer.transfer(msg.value);

        emit DonorAdded(msg.sender);
    }

    function subscribe() public payable subscriberNotExists(msg.sender) isEnoughSubscriptionFeeProvided(msg.value) {

        // add to subscribers
        subscribers[msg.sender] = true;

        //transfer ether to the streamer
        address payable streamer = payable (streamerChannelContract.getStreamer());
        streamer.transfer(msg.value);

        emit SubscriberAdded(msg.sender);

    }

    // print all donors
    function getAllDonors() public onlyStreamer {
        emit AllDonors(donors);
    }

    function getAllInteractionTypes() public view returns (uint256[] memory costs, string[] memory descriptions) {
        uint256 length = interactionCosts.length;
        costs = new uint256[](length);
        descriptions = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            costs[i] = interactionCosts[i].cost;
            descriptions[i] = interactionCosts[i].description;
        }

        return (costs, descriptions);
    }

}
