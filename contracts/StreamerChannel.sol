pragma solidity ^0.5.0;

contract StreamerChannel {

    address public attendanceSystemContract;
    address public predictionSystemContract;
    address public interactionSystemContract;
    address private streamer;
    mapping(address => bool) private moderators;
    mapping(address => uint256) private viewerTokens;
    
    constructor() public {
        streamer = msg.sender;
    }

    modifier streamerOnly(){
        require(streamer == msg.sender, "Only the streamer can call this function");
        _;
    }

    modifier issuingAdminOnly(){
        require(streamer == msg.sender || attendanceSystemContract == msg.sender || predictionSystemContract == msg.sender, "Only Admin can call this function");
        _;
    }

    modifier spendingAdminOnly(){
        require(interactionSystemContract == msg.sender || predictionSystemContract == msg.sender, "Only Admin can call this function");
        _;
    }

    function getStreamer() public view returns(address) {
        return streamer;
    }

    function getViewerTokens(address viewer) public view returns(uint256) {
        return viewerTokens[viewer];
    }

    function issueTokens(address viewer, uint256 amount) public issuingAdminOnly {
        viewerTokens[viewer] += amount;
    }

    function spendTokens(address viewer, uint256 amount) public spendingAdminOnly {
        viewerTokens[viewer] -= amount;
    }

    function addModerator(address newModerator) public streamerOnly {
        require(moderators[newModerator] == false, "The provided address already belongs to a moderator");
        moderators[newModerator] = true;
    }

    function removeModerator(address oldModerator) public streamerOnly {
        require(moderators[oldModerator] == true, "The provided address does not belong to a moderator");
        moderators[oldModerator] = false;
    }

    function setAttendanceSystemContract(address addr_ac) public streamerOnly {
        attendanceSystemContract = addr_ac;
    }

    function setPredictionSystemContract(address addr_pc) public streamerOnly {
        predictionSystemContract = addr_pc;
    }

    function setInteractionSystemContract(address addr_ic) public streamerOnly {
        interactionSystemContract = addr_ic;
    }

    function isStreamerOrMods(address checkAddress) public view returns(bool) {
        return checkAddress == streamer || moderators[checkAddress] == true;
    }
}
