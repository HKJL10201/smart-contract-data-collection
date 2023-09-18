// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

interface IVoting {
    
    function createElection(uint _registrationPeriod, uint _votingPeriod, uint _votingDeadline) external returns (uint);
    
    function registerCandidateForElection(uint _electionId, bytes32 _candidateName) external returns (bool);
    
    function vote(uint _electionId, address _candidateAddr) external returns (bool);
}