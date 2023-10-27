// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;


contract AttendanceSystem {
    uint256 attendanceAmount;
    uint256 timeLimit;
    bool allowAttending;
    mapping (address => uint256) viewerAttendance;
    address [] viewers;

    address owner;
    constructor(address streamerContractAddress) {
        // streamerChannel = streamerChannelAddr; // We'll use this when we are connecting things
        streamerChannelContract = streamerContractAddress;
    }

    // modifier streamerOnly(address addr) {
    //     // require(addr == streamerChannel.getStreamer());
    //     require(addr == owner, "Only streamers are allowed to startNewAttendance"); // just to check SC separately
    //     _;
    // }

    modifier  allowsAttending(uint256 callTime) {
        require(callTime < timeLimit, "Streamer has stopped streaming or the time slot has ran out");
        _;
    }

    function exists(address addr) private view returns (bool) {
        if (viewers.length > 0) {
            for (uint i = 0; i < viewers.length; i++) {
                if (viewers[i] == addr) {
                    return true;
                }
            }
        }
        
        return false;
    }


    function markMyAttendance() public allowsAttending(block.timestamp) {
        // If the user has clicked this button within the time range then set their amount
        // Also needs to make sure the user hasn't already marked Their Attendance
        if (exists(msg.sender)) {
            require(viewerAttendance[msg.sender] == 0, "Attendance already marked");
        }
        attendanceAmount =  timeLimit - block.timestamp;
        //TODO: Call issue token equivalent to the amount
        // Actually since everything is kinda fixed, we ca
        viewerAttendance[msg.sender] = block.timestamp;
        viewers.push(msg.sender);
    }

    function resetBalance() private  {
        for (uint i=0; i < viewers.length ; i++){
            viewerAttendance[viewers[i]] = 0;
        }
    }

    function startNewAttendance(uint attendancePeriod) public streamerChannelContract.streamerOnly(msg.sender) {
        // Attendance period is taken in minutes, so if value is 30, it means 30 minutes
        // This function allows streamers to set the timeperiod in which people can come in and mark their attendance
        // Between that time period anyone will be able to call markMyAttendance
        resetBalance();
        timeLimit = block.timestamp + (attendancePeriod*60);
    }
}
