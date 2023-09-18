// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract VotingSystem {
    address public owner;
    mapping(address => Voter) voters;
    Candidate[] candidates;
    uint256 public countOfCandidates;

    struct Voter {
        uint256 weight;
        bool voted;
        uint256 vote;
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier didNotVoteYet(){
        require(!voters[msg.sender].voted, "User has already voted.");
        _;
    }

    modifier isOwner(){
      require(msg.sender == owner, "The sender is not the owner.");
      _;
    }

    function addCandidate(string memory _name) public isOwner {
        candidates.push(Candidate({name: _name, voteCount: 0}));
        countOfCandidates++;
    }

    function voteForCandidateAt(uint256 _index) public didNotVoteYet {
        candidates[_index].voteCount++;
        voters[msg.sender].voted = true;
        voters[msg.sender].vote = _index;
    }

    function getCandidateAt(uint256 _index) public view returns (Candidate memory){
        return candidates[_index];
    }

    function getUserStatus() public view returns (bool, uint256){
        return (voters[msg.sender].voted, voters[msg.sender].vote);
    }
}