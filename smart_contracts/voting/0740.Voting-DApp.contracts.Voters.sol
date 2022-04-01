// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Election.sol";

contract Voters is Election {

    mapping (address => Voter) public voters;

    struct Voter {
        uint voterId;
        bool voted;
        uint selection;
    }

    uint public latestVoterId = 0;

    function createVoter() public {
        require(voters[msg.sender].voterId == 0);
        latestVoterId++;
        voters[msg.sender] = Voter(latestVoterId, false, 0);
    }

    function castVote(uint _candId) public {
        require(_candId > 0 && _candId <= candidates.length);
        require(voters[msg.sender].voted == false);
        voters[msg.sender].selection = _candId;
        voters[msg.sender].voted = true;
        votes[_candId]++;
    }

    function retractVote() public {
        require(voters[msg.sender].voted == true);
        votes[voters[msg.sender].selection]--;
        voters[msg.sender].voted = false;
        voters[msg.sender].selection = 0;
    }

    function changeVote(uint _candId) public {
        require(voters[msg.sender].voted == true);
        require(_candId > 0 && _candId <= candidates.length);
        votes[voters[msg.sender].selection]--;
        voters[msg.sender].selection = _candId;
        votes[voters[msg.sender].selection]++;
    }
}