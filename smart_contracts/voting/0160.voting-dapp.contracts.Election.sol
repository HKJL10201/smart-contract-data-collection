// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./IElection.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Election is IElection, Ownable, AccessControl {

    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    
    struct Candidate {
        bytes32 name;
        address addr;
        uint votesCount;
    }
    
    struct Voter {
        address voter;
        uint when;
    }
    
    uint registrationStart;
    uint registrationDeadline;
    uint votingStart;
    uint votingDeadline;
    
    mapping (address => Candidate) public candidates;
    mapping (address => mapping (address => Voter)) public candidatesToVoters;
    
    uint public maxVotesCount = 0;
    address public winner;
    
    constructor(uint _registrationStart, uint _registrationDeadline, uint _votingStart, uint _votingDeadline) {
        registrationStart = _registrationStart;
        registrationDeadline = _registrationDeadline;
        votingStart = _votingStart;
        votingDeadline = _votingDeadline;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    

    function isRegistrationOpened() external view override returns (bool) {
        return block.timestamp >= registrationStart && block.timestamp <= registrationDeadline;
    }
    
    function isVotingOpened() external view override returns (bool) {
        return block.timestamp >= votingStart && block.timestamp <= votingDeadline;
    }
    
    
    modifier registrationPeriodValid() {
        require(block.timestamp >= registrationStart && block.timestamp <= registrationDeadline);
        _;
    }

    modifier votingPeriodValid() {
        require(block.timestamp >= votingStart && block.timestamp <= votingDeadline);
        _;
    }
    
    function registerCandidate(bytes32 _candidateName) external override registrationPeriodValid returns (bool) {
        require(candidates[msg.sender].addr == address(0));
        candidates[msg.sender] = Candidate(_candidateName, msg.sender, 0);
        _setupRole(CANDIDATE_ROLE, msg.sender);
        return true;
    }

    function revokeCandidate() public returns (bool) {
        require(hasRole(CANDIDATE_ROLE, msg.sender), "Caller is not a candidate");
        require(candidates[msg.sender].addr != address(0), "Candidate has not been registered");
        // TODO: actions to revoke the candidate
    }
    
    function vote(address _candidate) external override votingPeriodValid returns (bool) {
        require(candidates[_candidate].addr != address(0));
        require(candidatesToVoters[_candidate][msg.sender].voter == address(0));
        
        candidatesToVoters[_candidate][msg.sender] = Voter(msg.sender, block.timestamp);
        
        uint votesCount = candidates[_candidate].votesCount++;
        if (votesCount > maxVotesCount) {
            winner = _candidate;
        }
        return true;
    }
    
    function getVotesFor(address _candidate) external view override returns (uint) {
        require(candidates[_candidate].addr != address(0));
        return candidates[_candidate].votesCount;
    }
    
    function getWinner() external view override returns (address) {
        return winner;
    }

    function haltElection() external onlyOwner {
        // TODO: halt logic
    }
    
}