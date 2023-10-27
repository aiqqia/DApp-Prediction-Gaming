pragma solidity ^0.5.0;

contract StreamerChannel {

    address public  attendanceContract;
    address public predictionSystemContract;
    address public interactionSystemContract;
    address private streamer;
    address[] public moderators;
    mapping(address => uint256) private viewerTokens;
    
    constructor() public {
        streamer = msg.sender;
    }

    modifier streamerOnly(){
        require(streamer == msg.sender, "Only the streamer can call this function");
        _;
    }

    modifier issuingAdminOnly(){
        require(streamer == msg.sender || attendanceContract == msg.sender || predictionSystemContract == msg.sender, "Only Admin can call this function");
        _;
    }

    modifier spendingAdminOnly(){
        require(interactionSystemContract == msg.sender || predictionSystemContract == msg.sender, "Only Admin can call this function");
        _;
    }

    function issueTokens(address viewer, uint256 amount) public issuingAdminOnly {
        viewerTokens[viewer] += amount;
    }

    function getViewerTokens(address viewer) public view returns(uint256) {
        return viewerTokens[viewer];
    }

    function getStreamer() public view returns(address) {
        return streamer;
    }

    function setAttendanceContract(address addr_ac) public {
        attendanceContract = addr_ac;
    }

    function setPredictionSystemContract(address addr_pc) public {
        predictionSystemContract = addr_pc;
    }

    function setInteractionSystemContract(address addr_ic) public {
        interactionSystemContract = addr_ic;
    }

    function spendTokens(address viewer, uint256 amount) public spendingAdminOnly {
        viewerTokens[viewer] -= amount;
    }

    function isStreamerOrMods(address checkAddress) public view returns(bool) {
        uint256 count = 0;
        for(uint256 i = 0; i < moderators.length; i++) {
            if(checkAddress == moderators[i])
                count++;
        }
        if(checkAddress == streamer || count > 0)
            return true;
        else 
            return false;
    }
}