//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./StreamerChannel.sol"; // Import the StreamChannel interface

contract InteractionSystem{
    StreamerChannel streamerChannelContract;
    address[] donors;
     
    mapping(address => bool) public subscribers;

    struct InteractionType {
        uint256 cost;
        string description;
    }

    InteractionType[] public interactions;

    struct ViewerInteractionRequest {
        uint256 interactionTypeIndex;
        address requester;
    }
    ViewerInteractionRequest[] public viewerInteractionRequestQueue;    

    uint256 currentViewerQueueIndex = 0;
    uint256 streamerCompletedQueueIndex = 0;

    event InteractionRequested(address requester, uint256 interactionCost, string description);
    event InteractionAdded(uint256 interactionCost, string interactionDescription);
    event InteractionPeek(uint256 streamerCompletedQueueIndex, uint256 InteractionType, address requester);
    event InteractionPop(uint256 InteractionType, address requester);
    event DonorAdded(address donor);
    event SubscriberAdded(address subscriber);
    event AllDonors(address[] donors);

    constructor(address streamChannelAddress) public {
        streamerChannelContract = StreamerChannel(streamChannelAddress);
        address streamer = streamerChannelContract.getStreamer();
        require(streamer == msg.sender, "Only Streamer can deploy this contract!");
        
        streamerChannelContract.setInteractionSystemContract(address(this));

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

    modifier isEnoughTokenBalance(address viewer, uint256 interactionTypeIndex){
        //require viewer token balance >= interactionCost
        require(streamerChannelContract.getViewerTokens(viewer) >= interactions[interactionTypeIndex].cost, "Viewer should have enough token balance!");
        _;
    }

    modifier isInteractionQueueEmpty(){
        require(currentViewerQueueIndex != streamerCompletedQueueIndex, "Interaction queue is empty currently...");
        _;
    }

    modifier isValidInteractionType(uint256 interactionTypeIndex) {
        require(interactionTypeIndex >= 0 && interactionTypeIndex < interactions.length, "Invalid interaction type");
        _;
    }

    function requestInteraction(uint256 interactionTypeIndex) public 
        isValidInteractionType(interactionTypeIndex)
        isEnoughTokenBalance(msg.sender, interactionTypeIndex) {
        
        //minus interactionCost from viewer token balance
        uint256 interactionCost = interactions[interactionTypeIndex].cost;
        streamerChannelContract.spendTokens(msg.sender, interactionCost);

        string memory interactionDescription = interactions[interactionTypeIndex].description;
        
        // add viewer request to queue
        viewerInteractionRequestQueue.push(ViewerInteractionRequest(interactionTypeIndex, msg.sender));

        //update viewer queue index
        currentViewerQueueIndex += 1;

        emit InteractionRequested(msg.sender, interactionCost, interactionDescription);
    }

    function makeDonation() public payable donationGreaterThanZero(msg.value){

        address streamer = streamerChannelContract.getStreamer();
        address payable payableStreamer = address(uint160(streamer));

        //check if alrdy in donors
        for(uint256 i=0; i < donors.length; i++){
            address donor = donors[i];
            if(donor == msg.sender){
                //transfer ether to the streamer
                payableStreamer.transfer(msg.value);
                return;
            }
        }
        //add to donors
        donors.push(msg.sender);

        //transfer ether to the streamer
        payableStreamer.transfer(msg.value);

        emit DonorAdded(msg.sender);
    }

    function subscribe() public payable subscriberNotExists(msg.sender) isEnoughSubscriptionFeeProvided(msg.value) {

        // add to subscribers
        subscribers[msg.sender] = true;

        //transfer ether to the streamer
        address streamer = streamerChannelContract.getStreamer();
        address payable payableStreamer = address(uint160(streamer));
        payableStreamer.transfer(msg.value);

        emit SubscriberAdded(msg.sender);

    }

    // function to allow only streamers to add types of interaction available
    function addInteraction(uint256 cost, string memory description) public onlyStreamer{
        interactions.push(InteractionType(cost, description));
        emit InteractionAdded(cost, description);
    }

    // for streamer to view the next viewer's request in interaction queue
    function peekNextInteraction() public onlyStreamer isInteractionQueueEmpty 
        returns(uint256, string memory, address)    
    {
        uint256 interactionTypeIndex = viewerInteractionRequestQueue[streamerCompletedQueueIndex].interactionTypeIndex;
        address requester = viewerInteractionRequestQueue[streamerCompletedQueueIndex].requester;
        emit InteractionPeek(streamerCompletedQueueIndex, interactionTypeIndex, requester);
        return (interactionTypeIndex, interactions[interactionTypeIndex].description, requester);
    }

    // for streamer to proceed to the next request in the queue
    function popNextInteraction() public onlyStreamer isInteractionQueueEmpty{
        uint256 interactionTypeIndex = viewerInteractionRequestQueue[streamerCompletedQueueIndex].interactionTypeIndex;
        address requester = viewerInteractionRequestQueue[streamerCompletedQueueIndex].requester;
        streamerCompletedQueueIndex += 1;

        emit InteractionPop(interactionTypeIndex, requester);
    }

    function getStreamerCompletedQueueIndex() public view returns (uint256) {
        return streamerCompletedQueueIndex;
    }

    // print all donors
    function getAllDonors() public {
        emit AllDonors(donors);
    }

    // print all interaction types available for viewers
    function getAllInteractionTypes() public view returns (uint256[] memory costs, string[] memory descriptions) {
        uint256 length = interactions.length;
        costs = new uint256[](length);
        descriptions = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            costs[i] = interactions[i].cost;
            descriptions[i] = interactions[i].description;
        }

        return (costs, descriptions);
    }

}
