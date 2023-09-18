// SPDX-License-Identifier: GPL-3.0

// Smart Contract for school headboy/headgirl election

pragma solidity >=0.7.0 <0.9.0;

contract VotingSmartContract {
    address admin; //principal of school
    address public winner;

    struct Voter {
        //students participanting in elections as voters
        string name;
        uint class;
        uint voterId;
        uint voteCandidateId;
        address voterAddress;
    }

    struct Candidate {
        //students participating as candidates
        string name;
        uint class;
        uint candidateId;
        uint votes;
        address candidateAddress;
    }

    uint nextVoterId = 1;
    uint nextCandidateId = 1;

    mapping(uint => Voter) voterDetails; //details of student voters
    mapping(uint => Candidate) candidateDetails; //details of candidate

    constructor() {
        admin = msg.sender; //principal will deploy the contract
    }

    // for event emmision after candidate and voter registration  and casting of vote
    event CadidateRegistered(string _name, uint _class);
    event VoterRegistered(string _name, uint _class);
    event VoteCasted(uint _voterId, uint _id);

    function registerCandidate(string calldata _name, uint _class) external {
        //principal cannot be a candidate
        require(msg.sender != admin, "You cannot register");
        candidateDetails[nextCandidateId] = Candidate(
            _name,
            _class,
            nextCandidateId,
            0,
            msg.sender
        );
        nextCandidateId++;

        emit CadidateRegistered(_name, _class);
    }

    function registerVoter(string memory _name, uint _class) external {
        voterDetails[nextVoterId] = Voter(
            _name,
            _class,
            nextVoterId,
            0,
            msg.sender
        );
        nextVoterId++;

        emit VoterRegistered(_name, _class);
    }

    function vote(uint _voterId, uint _id) external {
        //To avoid multiple voting by single voter
        require(
            voterDetails[_voterId].voteCandidateId == 0,
            "You already voted!"
        );
        voterDetails[_voterId].voteCandidateId = _id;
        candidateDetails[_id].votes++;

        //emmision of event
        emit VoteCasted(_voterId, _id);
    }

    function result() external {
        require(msg.sender == admin, "Only Principal can check the result.");

        uint maxVotes = 0;
        address currentWinner;

        for (uint i = 1; i < nextCandidateId; i++) {
            if (candidateDetails[i].votes > maxVotes) {
                maxVotes = candidateDetails[i].votes;
                currentWinner = candidateDetails[i].candidateAddress;
            }
        }
        winner = currentWinner;
    }
}
