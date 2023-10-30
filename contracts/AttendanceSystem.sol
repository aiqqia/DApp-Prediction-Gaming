// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
import "./StreamerChannel.sol";

contract AttendanceSystem {
    StreamerChannel streamerChannelContract;
    uint256 attendanceAmount;
    uint256 timeLimit;
    mapping (address => uint256) viewerAttendance;
    address [] viewers;

    address owner;
    constructor(address streamerContractAddress) public {
        streamerChannelContract = StreamerChannel(streamerContractAddress);
        attendanceAmount = 30; // Default value, call setAttendanceAmount() to change
    }

    modifier onlyStreamer() {
        require(streamerChannelContract.getStreamer() == msg.sender, "Only Streamer are allowed to startNewAttendance");
        _;
    }
    modifier allowsAttending(uint256 callTime) {
        require(callTime < timeLimit, "Streamer has stopped streaming or the time slot has ran out");
        require(viewerAttendance[msg.sender] < timeLimit, "Attendance has already been marked");
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount >= 0, "The number of tokens awarded for attendance cannot be less than 0");
        _;
    }

    function setAttendanceAmount(uint256 newAmount) public onlyStreamer validAmount(newAmount) {
        attendanceAmount = newAmount;
    }

    function getAttendanceAmount() public view returns(uint256) {
        return attendanceAmount;
    }

    function markMyAttendance() public allowsAttending(block.timestamp) {
        // If the user has clicked this button within the time range then set their amount
        // Also needs to make sure the user hasn't already marked Their Attendance
        streamerChannelContract.issueTokens(msg.sender, attendanceAmount);
        viewerAttendance[msg.sender] = timeLimit;
    }

    function startNewAttendance(uint attendancePeriod) public onlyStreamer {
        // Attendance period is taken in minutes, so if value is 30, it means 30 minutes
        // This function allows streamers to set the timeperiod in which people can come in and mark their attendance
        // Between that time period anyone will be able to call markMyAttendance
        timeLimit = block.timestamp + (attendancePeriod*60);
    }

    function getTimeLimit() public view returns(uint256) {
        return timeLimit;
    }

    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }
}
