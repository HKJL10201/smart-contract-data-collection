pragma solidity >=0.4.21 < 0.6.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ElectionStorage is Ownable {

    // Model a Candidate
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    // Store Candidates Count
    uint public candidatesCount;

    // Read/write Candidates
    mapping(uint => Candidate) public candidates;

    mapping(address => bool) public authorizedContracts;

    constructor () public {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    // Only allow access from the authorized Election contract
    modifier onlyElectionContract() {
        require(authorizedContracts[msg.sender]);
        _;
    }

    function addAuthorizedContract(address _contract) onlyOwner public {
        authorizedContracts[_contract] = true;
    }

    function addCandidate(string _name) private {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function increaseVoteCount(uint _candidateId) onlyElectionContract external returns (bool) {
        candidates[_candidateId].voteCount ++;
        return true;
    }
}