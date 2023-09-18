// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract vote {
    struct Voter {
       uint vote;
       bool hasVoted;
    }
    mapping(address => Voter) public voters;

    uint public ironmanVotes;
    uint public capVotes;

    uint public voteDeadline = block.timestamp + 7 days;

    function vote_for_ironman () public {
        require(voteDeadline > block.timestamp, "time to vote has expired");
        require(voters[msg.sender].hasVoted == false, "you have already voted");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].vote = 1;
        ironmanVotes ++;

    }

    function vote_for_cap () public {
        require(voteDeadline > block.timestamp, "time to vote has expired");
        require(voters[msg.sender].hasVoted == false, "you have already voted");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].vote = 2;
        capVotes ++;
    }

        function Results() public pure returns(uint _ironmanVotes, uint _capVotes){
            return (_ironmanVotes, _capVotes);
        }  
}