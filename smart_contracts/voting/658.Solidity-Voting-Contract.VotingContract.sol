// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract VotingSystem {
    using SafeMath for uint;

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    uint public candidatesCount;

    // For storing votes cast by each voter
    mapping(address => uint) public votesCast;

    event Voted(uint indexed _candidateId);

    modifier validCandidate(uint _candidateId) {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Not a valid candidate");
        _;
    }

    modifier hasNotVoted(address _voter) {
        require(votesCast[_voter] == 0, "Voter has already voted");
        _;
    }

    constructor() {
        addCandidate("Candidate 1");
        addCandidate("Candidate 2");
    }

    function addCandidate(string memory _name) private {
        candidatesCount = candidatesCount.add(1);
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public validCandidate(_candidateId) hasNotVoted(msg.sender) {
        votesCast[msg.sender] = _candidateId;

        // update candidate vote Count
        candidates[_candidateId].voteCount = candidates[_candidateId].voteCount.add(1);

        // trigger voted event
        emit Voted(_candidateId);
    }
}

