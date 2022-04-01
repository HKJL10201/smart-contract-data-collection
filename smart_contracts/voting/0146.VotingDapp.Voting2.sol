// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Voting{

    struct candidate {
        uint id;
        string name;
        uint voteCount;
    }
    mapping(address => bool) public voters;
    mapping(uint => candidate) public candidates;
    
    uint public candidateCount;

    function addCandidate(string memory name) private {
        candidates[candidateCount] = candidate(candidateCount, name, 0);
        candidateCount++;

    }
    
    function setCandiate() public{
        addCandidate("Daniel");
        addCandidate("Sungwon");
    }

    function voteForCandidate(uint _candidateId) public {
        require(!voters[msg.sender]);
        require(_candidateId <= candidateCount);

        candidates[_candidateId].voteCount++;

    }

}