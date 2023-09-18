// SPDX-License-Identifier: MIT
pragma solidity >=0.7.4;


contract Voting {

    struct Candidate {
        uint id;
        string name;
        uint age;
        uint voteCount;
    }

    mapping(address => bool) public voters;

    mapping(uint => Candidate) public candidates;

    uint public candidatesCount;


    function addCandidate(string memory _name,uint _age) public {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,_age,0);
    }

    function vote(uint _id) public {
        require(!voters[msg.sender]);
        
        require(_id > 0 && _id <= candidatesCount);

        voters[msg.sender] = true;

        candidates[_id].voteCount++;
    }

}