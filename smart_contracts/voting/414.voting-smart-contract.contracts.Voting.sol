// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Voting{
    address owner;

    struct Candidate{
        uint id;
        string name;
        string party;
        string constituency;
        uint256 votes;
    }

    struct Voter{
        address voterAddress;
        uint voterId;
        string name;
        string constituency;
        bool isVoted;
    }

    Candidate[] public candidates;

    mapping(address=>bool) public voted;
    constructor (){
        owner  = msg.sender;
    }

    function addCandidate(Candidate memory candidate)public onlyOwner {
        candidates.push(candidate);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    function vote(uint candidateId)public {
        require(voted[msg.sender]==false,"Your vote is already registered");
        candidates[candidateId].votes++;
        voted[msg.sender] = true;
    }

    function getResults(uint candidateId)public view returns(uint256){
        return candidates[candidateId].votes;
    }

    function getLengthOfCandidates()public view returns(uint256){
        return candidates.length;
    }
}