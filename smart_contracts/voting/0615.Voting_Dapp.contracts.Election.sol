//SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

contract Election {
    //Rough Model of the Candidate
    struct Candidate{
        uint id;
        string name;
        string party;
        uint vote;
    }
    //storing candidate
    mapping(address => bool) public voters;
    //reading candidate
    mapping(uint => Candidate) public candidates;
    //Keeping Track of votes
    uint public candidatesCount;
    string public candidate;    
    //constructor
    event votedEvent (
        uint indexed _candidateId
    );
    constructor() public {
        
        addCandidate("Chimatu","Congress");
        addCandidate("Chirag","BJP");
        addCandidate("Prachi","Tridnimul");
        addCandidate("Bhandari","Sapa");
        addCandidate("Reetesh","Bahujan Sanaj Party");  
    }

    function addCandidate (string memory _name,string memory _party) private {
        candidatesCount += 1;
        candidates[candidatesCount] = Candidate(candidatesCount,_name,_party,0);
        
    }
    function vote(uint _candidateId) public {
        require(!voters[msg.sender]);

        require(_candidateId > 0 &&  _candidateId <=candidatesCount);
        voters[msg.sender] = true;

        candidates[_candidateId].vote ++;

        emit votedEvent(_candidateId);
    }
}
//Election.deployed().then(function(instance) { app = instance })