//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract Voting {
    
    uint y;
    uint n;
    uint t;
    
    mapping(address => bool) public votingStatus;
    uint[] passed;
    uint[] rejected;

    function voteYes() external {
        require(votingStatus[msg.sender] == false, "you have already voted");
        votingStatus[msg.sender] = true;
        y++;
    }

    function voteNo() external {
        require(votingStatus[msg.sender] == false, "you have already voted");
        votingStatus[msg.sender] = true;
        n++;
    }

    function closeVoting() external  {
        uint totalVotes = y + n;
        uint percentage1 = y*100;
        uint percentage2 = percentage1/totalVotes;
        if(percentage2 >= 60) {
            passed.push(2);
        } else {
            rejected.push(9);
        }
    }

    function getArray() external view returns(uint[] memory, uint[]memory) {
        return (passed, rejected);
    }

}


