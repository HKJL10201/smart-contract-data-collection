pragma solidity ^0.8.9;

contract Voting{
    
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    uint public candidatesCount;

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voteflag;
    //event votingupdate(uint  id , string name , uint vote);

    constructor() {
        addCandidate("Alice");
        addCandidate("Bob");
    }

    function addCandidate(string memory name) private {
       candidatesCount++;
       candidates[candidatesCount]= Candidate(candidatesCount,name,0); 
    }

    function vote(uint _id) public {
       require(!voteflag[msg.sender]);
       require(_id > 0 && _id <= candidatesCount );

       voteflag[msg.sender]=true;
       candidates[ _id ].voteCount ++;
       //emit votingupdate(_id,candidates[_id].name,candidates[_id].voteCount);

    } 
}