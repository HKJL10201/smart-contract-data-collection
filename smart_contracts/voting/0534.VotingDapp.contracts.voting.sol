//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract voting {
    mapping(address => uint) voters; //storing voters who have voted
    mapping(address => uint) votecount; //total votes

    //vote button

    function vote(address candidate) public {
        require(voters[msg.sender] == 0, "You have already voted");
        voters[msg.sender] = 1;
        votecount[candidate] += 1;

        //will do vote++ in javascript file
    }

    //get vote counts

    function getVoteCount(address candidate) public view returns (uint) {
        return votecount[candidate];
    }

    // fund the candidate

    function SendEth(address payable candidate) public payable {
        require(msg.value >= 0.05 ether, "should be atleast 1 ether");
        candidate.transfer(msg.value);
    }

    //get Total Funds

    function GetTotalFunds(address candidate) public view returns (uint) {
        return candidate.balance;
    }
}
