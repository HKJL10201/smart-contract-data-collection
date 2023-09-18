pragma solidity ^0.4.24;

contract Voting {
    struct Proposal {
        bytes32 description;
        uint voteCount;
    }

    struct Voter {
        bool voted;
        bool isValid;
    }

    struct Poll {
        bool closed;
        string description;
        uint proposalsCount;
        mapping (uint => Proposal) proposals;
        mapping (bytes32 => Voter) voters;
    }

    /**
    * Events
    */

    event pollCreated(uint id, string description);
    event pollEnded(uint id);

    /**
    * State
    */

    uint[] internal _indexes;
    mapping (uint => Poll) internal _polls;

    /**
    * Transactions
    */

    function createPoll(string description, bytes32[] proposals, bytes32[] tokens) public {
        require(proposals.length > 1, "At least two proposals/candidates are needed.");
        require(tokens.length > 1, "At least two voter tokens are needed.");

        uint index = _indexes.length;
        _indexes.push(index);
        _polls[index] = Poll(false, description, proposals.length);

        for (uint i = 0; i < proposals.length; i++) {
            _polls[index].proposals[i] = Proposal(proposals[i], 0);
        }
        for (uint j = 0; j < tokens.length; j++) {
            _polls[index].voters[tokens[j]] = Voter(false, true);
        }
        emit pollCreated(index, description);
    }

    function castVote(bytes32 token, uint pollIndex, uint proposalIndex) public {
        Poll storage poll = _polls[pollIndex];
        Voter storage voter = poll.voters[token];
        Proposal storage proposal = poll.proposals[proposalIndex];

        require(poll.closed == false, "Poll is closed.");
        require(voter.isValid == true, "Invalid token.");
        require(voter.voted == false, "Voter already cast his vote.");

        proposal.voteCount = proposal.voteCount + 1;
        voter.voted = true;
    }

    function closePoll(uint index) public {
        Poll storage poll = _polls[index];
        require(poll.closed == false, "Poll already closed.");
        poll.closed = true;
        emit pollEnded(index);
    }

    /**
    * Getters
    */

    function getPollsMapSize() external view returns (uint) {
        return _indexes.length;
    }

    function getPoll(uint index) external view returns (string, uint, bool) {
        Poll storage poll = _polls[index];
        return (poll.description, poll.proposalsCount, poll.closed);
    }

    function getProposal(uint pollIndex, uint index) external view returns (bytes32) {
        Poll storage poll = _polls[pollIndex];
        return poll.proposals[index].description;
    }

    function getVoteCount(uint pollIndex, uint proposalIndex) external view returns (uint) {
        Poll storage poll = _polls[pollIndex];
        require(poll.closed == true, "Poll is not ended.");
        return poll.proposals[proposalIndex].voteCount;
    }
}