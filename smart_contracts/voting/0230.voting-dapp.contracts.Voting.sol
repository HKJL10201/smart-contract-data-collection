// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./IVoting.sol";
import "./Election.sol";

contract Voting is IVoting {
    
    mapping(uint => Election) public elections;
    uint latestElectionId = 0;
    
    
    function createElection(uint _registrationPeriod, uint _votingPeriod, uint _votingDeadline) external override returns (uint) {
        uint votingDeadline = _votingDeadline;
        uint votingStart = _votingDeadline - _votingPeriod;
        uint registrationDeadline = votingStart - 1;
        uint registrationStart = registrationDeadline - _registrationPeriod;
        require(votingStart >= block.timestamp, "Modify registration/voting periods or provide later voting deadline");

        latestElectionId++;
        elections[latestElectionId] = new Election(registrationStart, registrationDeadline, votingStart, votingDeadline);
        return latestElectionId;
    }
    
    function registerCandidateForElection(uint _electionId, bytes32 _candidateName) external override returns (bool) {
        require(_electionId <= latestElectionId);
        return elections[_electionId].registerCandidate(_candidateName); // TODO: pass original msg.sender as an address
    }
    
    function vote(uint _electionId, address _candidateAddr) external override returns (bool) {
        require(_electionId <= latestElectionId);
        return elections[_electionId].vote(_candidateAddr);
    }
}