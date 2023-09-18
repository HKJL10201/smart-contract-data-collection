// SPDX-License-Identifier: MIT
pragma solidity >=0.4.2;

contract Election {
    //model a candidate

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    //store candidate
    mapping(uint=>Candidate) public candidatesMap;


    //fetch candidate
    //vote count
    //store count
    uint public candidatesCount;


    function addCandidate (string memory _name) private{
        candidatesCount++;
        candidatesMap[candidatesCount] = Candidate(candidatesCount, _name, 0);

    }


    //constructor
    constructor() public {
        addCandidate("candy");
        addCandidate("hooly");
    }



}
