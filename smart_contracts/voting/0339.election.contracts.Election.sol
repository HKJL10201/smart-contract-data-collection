pragma solidity ^0.5.0;

contract Election{

    //to model a candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    
    //to store candidates
    //candidate ID mapped to candidate
    mapping (uint => Candidate) public candidates;

    address public owner;

    mapping (address => bool) private voted;

    uint public candidateCount;

    constructor() public {
        owner = msg.sender;
        voted[owner] = false;
        
        addCandidate("C1");
        addCandidate("C2");
    }

    //underscore means local variable, not state variable
    function addCandidate(string memory _name) private{


        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0);
    }

    function getCandidate(uint id) public view returns(string memory){
        return string(abi.encodePacked("Name: ",candidates[id].name));
    }

    function getVote(uint id) public view returns(uint){
        return candidates[id].voteCount;
    }

    function addVote(uint id) public{
        require(msg.sender == owner);
        require(!voted[msg.sender], "Already Voted!");
        candidates[id].voteCount++;
        voted[owner] = true;
    }
}