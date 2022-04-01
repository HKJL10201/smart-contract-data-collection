// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.8.0;

contract MyBallot{
    
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    struct Voter{
        address _address;
        bool voted;
    }


    address public owner;
    uint public winningCandidateId;
    Candidate[] public candidates;
    Voter[] voters;
    uint public candidatesCount = 0;
    uint public winningVoteCount = 0;
    bool public isVoteEnded = false;


    mapping(address => bool) public hasVoted;
    mapping(address => bool) public isVoter;

    constructor() {
        owner = msg.sender;
    }

    function addCandidate(string memory _name) public {
        require(msg.sender == owner);
        Candidate memory newCandidate = Candidate({
            id : candidatesCount,
            name : _name,
            voteCount : 0
        });
        
        candidates.push(newCandidate);
        candidatesCount += 1;
    }

    function addVoter(address _address) public {
        require(msg.sender == owner);
        Voter memory newVoter = Voter({
            _address : _address, 
            voted: false
        });
        isVoter[_address] = true;
        voters.push(newVoter);
    }
    
    function getCandidatesId() public view returns (uint[] memory ) {
        uint[] memory list = new uint[](candidatesCount);
        for(uint i = 0; i < candidatesCount; i++) {
            list[i] = candidates[i].id;
        }
        return list;
    }


    function vote(uint256 candidateId) public {
        require(isVoter[msg.sender], "Voter is not registered");
        require(!hasVoted[msg.sender], "Voter has already voted");
        require(!isVoteEnded, "voting process has ended");

       candidates[candidateId].voteCount += 1;
       if ( candidates[candidateId].voteCount > winningVoteCount ) {
            winningCandidateId = candidateId;
            winningVoteCount = candidates[candidateId].voteCount;
        }

        
        hasVoted[msg.sender] = true;
    }

    function endVote() public {
        require(msg.sender == owner);
        isVoteEnded = true;
    }
}