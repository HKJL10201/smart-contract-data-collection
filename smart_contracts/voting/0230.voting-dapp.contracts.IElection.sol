// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

interface IElection {
    
    function isRegistrationOpened() external view returns (bool);
    
    function isVotingOpened() external view returns (bool);
    
    function registerCandidate(bytes32 _candidateName) external returns (bool);
    
    function vote(address _candidateAddr) external returns (bool);
    
    function getVotesFor(address _candidateAddr) view external returns (uint);
    
    function getWinner() external view returns (address);
    
    function haltElection() external;
}