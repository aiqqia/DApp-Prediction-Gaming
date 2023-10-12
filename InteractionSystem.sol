//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract InteractionSystem{
    address streamChannelContract;
    address[] donors;
     
    mapping(address => bool) public subscribers;

    // map interactionCost to interactionType
    mapping(uint256 => uint256) public interactionCosts;

    event InteractionRequested(address requester, uint256 interactionCost);
    event DonorAdded(address donor);
    event SubscriberAdded(address subscriber);

    constructor(address streamChannelAddress) {
        require(streamChannelAddress.streamer() == msg.sender, "Only Streamer can deploy this contract!");
        streamChannelContract = streamChannelAddress;

    }

    function requestInteraction(uint256 interactionCost) public {
        //require caller token balance >= interactionCost
        require(streamChannelContract.getViewerTokens(msg.sender) >= interactionCost);

        //require valid interactionCost
        require(interactionCost[interactionCost] > 0, "Invalid interaction cost");

        //minus interactionCost from caller token balance
        streamChannelContract.spendTokens(msg.sender, interactionCost);

        emit InteractionRequested(msg.sender, interactionCost);
    }

    function makeDonation() public payable {
        //require msg.value > 0 eth
        require(msg.value > 0 ether, "Donation cannot be 0 ether!");
        //check if alrdy in donors
        for(uint256 i=0; i < donors.length; i++){
            address donor = donors[i];
            if(donor == msg.sender){
                return;
            }
        }
        //add to donors
        donors.push(msg.sender);

        emit DonorAdded(msg.sender);
    }

    function subscribe() public payable {
        //subscription fee 1 eth
        uint256 subscriptionFee = 1 ether;

        //require msg.value >= 1 eth
        require(msg.value >= subscriptionFee, "Subscription requires at least 1 ether!");
        //require not part of subscribers list
        require(subscribers[msg.sender] == false, "msg.sender is already a subscriber!");
        // add to subscribers
        subscribers[msg.sender] = true;

        emit SubscriberAdded(msg.sender);

    }

}