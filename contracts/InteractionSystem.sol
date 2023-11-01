//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./StreamerChannel.sol"; // Import the StreamChannel interface

contract InteractionSystem{
    StreamerChannel streamerChannelContract;
    uint256 subscriptionFee = 1 ether; // Subscription fee default at 1 ether
    uint256 subscriptionDuration = 30 * 24 * 60 * 60; // Subscription duration default at 30 days
     
    mapping(address => uint256) public subscribers; // Maps address to date
    mapping(address => uint256) public donors; // Maps address to amount donated

    struct InteractionType {
        uint256 cost;
        string description;
    }

    struct ViewerInteractionRequest {
        uint256 interactionTypeIndex;
        address requester;
    }

    InteractionType[] public interactions;
    ViewerInteractionRequest[] public viewerInteractionRequestQueue;    

    uint256 currentViewerQueueIndex = 0;
    uint256 streamerCompletedQueueIndex = 0;

    event InteractionRequested(address requester, uint256 interactionCost, string description);
    event InteractionAdded(uint256 interactionCost, string interactionDescription);
    event InteractionPop(uint256 InteractionType, address requester);
    event DonorAdded(address donor);
    event SubscriberAdded(address subscriber);
    event AllDonors(address[] donors);

    constructor(address streamChannelAddress) public {
        streamerChannelContract = StreamerChannel(streamChannelAddress);
    }

    modifier onlyStreamer() {
        require(streamerChannelContract.getStreamer() == msg.sender, "Only Streamer can call this function");
        _;
    }

    modifier donationGreaterThanZero(uint256 value) {
        require(value > 0, "Donation cannot be 0 ether!");
        _;
    }

    modifier isEnoughSubscriptionFeeProvided(uint256 value) {
        require(msg.value >= subscriptionFee, "The amount provided is not enough for the subscription!");
        _;
    }

    modifier isEnoughTokenBalance(address viewer, uint256 interactionTypeIndex) {
        //require viewer token balance >= interactionCost
        require(streamerChannelContract.getViewerTokens(viewer) >= interactions[interactionTypeIndex].cost, "Viewer does not have enough token balance for requested interaction!");
        _;
    }

    modifier isInteractionQueueEmpty() {
        require(currentViewerQueueIndex != streamerCompletedQueueIndex, "Interaction queue is currently empty...");
        _;
    }

    modifier isValidInteractionType(uint256 interactionTypeIndex) {
        require(interactionTypeIndex >= 0 && interactionTypeIndex < interactions.length, "Invalid interaction type");
        _;
    }

    // -- FUNCTIONS FOR VIEWERS --
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

    function makeDonation() public payable donationGreaterThanZero(msg.value) {
        address streamer = streamerChannelContract.getStreamer();
        address payable payableStreamer = address(uint160(streamer));
        payableStreamer.transfer(msg.value);
        
        //add to donors
        donors[msg.sender] += msg.value;
        emit DonorAdded(msg.sender);
    }

    function getSubscriptionFee() public view returns(uint256) {
        return subscriptionFee;
    }

    function getSubscriptionDuration() public view returns(uint256) {
        return subscriptionDuration;
    }

    function subscribe() public payable isEnoughSubscriptionFeeProvided(msg.value) {
        //transfer ether to the streamer
        address streamer = streamerChannelContract.getStreamer();
        address payable payableStreamer = address(uint160(streamer));
        payableStreamer.transfer(subscriptionFee);
        address(uint160(msg.sender)).transfer(msg.value - subscriptionFee); // Return remaining after charging subscription fee

        // add to subscribers
        if (subscribers[msg.sender] < block.timestamp) {
            subscribers[msg.sender] = block.timestamp + subscriptionDuration;
        } else {
            subscribers[msg.sender] += subscriptionDuration;
        }

        emit SubscriberAdded(msg.sender);
    }

    // -- FUNCTIONS FOR STREAMERS --
    // function to allow only streamers to add types of interaction available
    function addNewInteraction(uint256 cost, string memory description) public onlyStreamer {
        interactions.push(InteractionType(cost, description));
        emit InteractionAdded(cost, description);
    }

    // for streamer to view the next viewer's request in interaction queue
    function peekNextInteraction() public view onlyStreamer isInteractionQueueEmpty 
        returns(uint256, string memory, address) {
        uint256 interactionTypeIndex = viewerInteractionRequestQueue[streamerCompletedQueueIndex].interactionTypeIndex;
        address requester = viewerInteractionRequestQueue[streamerCompletedQueueIndex].requester;

        return (interactionTypeIndex, interactions[interactionTypeIndex].description, requester);
    }

    // for streamer to proceed to the next request in the queue
    function popNextInteraction() public onlyStreamer isInteractionQueueEmpty 
        returns(uint256, string memory, address) {
        uint256 interactionTypeIndex = viewerInteractionRequestQueue[streamerCompletedQueueIndex].interactionTypeIndex;
        address requester = viewerInteractionRequestQueue[streamerCompletedQueueIndex].requester;
        streamerCompletedQueueIndex += 1;

        emit InteractionPop(interactionTypeIndex, requester);
        return (interactionTypeIndex, interactions[interactionTypeIndex].description, requester);
    }

    function getStreamerCompletedQueueIndex() public view returns (uint256) {
        return streamerCompletedQueueIndex;
    }

    function setSubscriptionFee(uint256 newSubscriptionFee) public onlyStreamer {
        require(newSubscriptionFee > 0, "Subscription fee should be a value > 0 in terms of wei.");
        subscriptionFee = newSubscriptionFee;
    }

    function setSubscriptionDuration(uint256 newSubscriptionDuration) public onlyStreamer {
        require(newSubscriptionDuration > 0, "Subscription duration should be a value > 0 in terms of seconds.");
        subscriptionDuration = newSubscriptionDuration; // Value in seconds
    }

    // -- UTILITY FUNCTIONS --
    function isSubscribed(address viewer) public view returns (bool) {
        return subscribers[viewer] > block.timestamp;
    }

    function isDonor(address viewer) public view returns (bool) {
        return donors[viewer] > 0;
    }
}
