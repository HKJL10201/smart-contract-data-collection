// SPDX-License-Identifier: MIT
pragma solidity >=0.5.2;

contract Election {
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    struct Voter {
        uint256 id;
        string name;
        bool hasVoted;
    }

    mapping(uint256 => Candidate) public candidates;

    mapping(uint256 => Voter) public voters;

    uint256 public candidatesCount;

    uint256 public voterCount;

    // voted event
    //event votedEvent(uint256 indexed _candidateId);

    constructor() public {
        addCandidate(1, "John Wick");
        addCandidate(2, "Browney Jr");
        addCandidate(3, "Helena Williams");
        addVoter(4, "Voter 1");
        addVoter(5, "Voter 2");
    }

    function addCandidate(uint256 _id, string memory _name) private {
        candidatesCount++;
        candidates[_id] = Candidate(_id, _name, 0);
    }

    function addVoter(uint256 _id, string memory _name) private {
        voterCount++;
        voters[_id] = Voter(_id, _name, false);
    }

    function vote(uint256 _candidateId, uint256 _voterId) public {
        // require that they haven't voted before
        require(!voters[_voterId].hasVoted);

        // require a valid candidate and valid voter
        require(
            _candidateId > 0 &&
                _candidateId == candidates[_candidateId].id &&
                _voterId > 0 &&
                _voterId == voters[_voterId].id
        );

        // record that voter has voted
        voters[_voterId].hasVoted = true;

        // update candidate vote Count
        candidates[_candidateId].voteCount++;

        // trigger voted event
        //emit votedEvent(_candidateId);
    }
}
