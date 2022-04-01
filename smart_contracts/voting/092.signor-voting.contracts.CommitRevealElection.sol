pragma solidity ^0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./Election.sol";

contract CommitRevealElection is Election {

    uint revealTime;


    mapping (address => bytes32) secretVotes;
    mapping (address => bool) voteRevealed;
    uint public votesRevealed;


    constructor (uint _startTime, uint _endTime, uint _revealInterval, address[] memory _initialVoters) Election(_startTime, _endTime) public {
        addVoters(_initialVoters);
        revealTime = _endTime + _revealInterval;
    }

    function vote(bytes32 _hash) public onlyVoter votingOpen {
        require(!voted[msg.sender], "already voted");

        voted[msg.sender] = true;
        secretVotes[msg.sender] = _hash;
        votesReceived++;
    }

    function revealVote(bytes32 _candidate, bytes32 _salt) public onlyVoter {
        require(now >= endTime && now <= revealTime);
        require(voted[msg.sender], "voter has not voted");
        require(!voteRevealed[msg.sender], "voter has already revealed vote");
        require(isCandidate(_candidate), "not a valid candidate");

        bytes32 voteHash = keccak256(abi.encode(_candidate, _salt));

        require(voteHash == secretVotes[msg.sender], "vote revealed does not match secret vote");

        voteCount[_candidate]++;
        voteRevealed[msg.sender] = true;
        votesRevealed++;
    }

}