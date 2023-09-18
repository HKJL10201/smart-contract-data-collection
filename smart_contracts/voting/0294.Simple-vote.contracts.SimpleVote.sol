pragma solidity ^0.8.0;

contract Simplevote {
	
	struct Voter {
        uint canVote;
        bool voted;
		address delegate;
		uint vote;
	}	
	
	struct Proposal {
		uint id;
		string name;
		uint votes;
	}
	
	struct Ballot {
		uint id;
		string name;
		Proposal[] proposals;
		uint end;
	}
	
	address public owner;
	
	constructor() {
		owner = msg.sender;
	}

    mapping(uint => mapping(address => Voter)) public voters;
    mapping(uint => Ballot) public ballots;
    mapping(uint => mapping(address => bool)) public votes;

    uint public ballotCount;

    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner');
        _;
    }

    // Add voters to the ballot
    function addVoters(address[] calldata _voters, uint ballotId) external onlyOwner() {

        require(ballotCount > 0, 'No active proposals');

        for(uint i = 0;i < _voters.length;i++) {
            require(!voters[ballotId][_voters[i]].voted, 'The voter has already voted');
            voters[ballotId][_voters[i]].canVote = 1;
        }
    }

    // Create a ballot 
    function createBallot(string memory name, string[] memory _proposals, uint duration) public onlyOwner() {
        ballotCount++;
        ballots[ballotCount].id = ballotCount;
        ballots[ballotCount].name = name;
        ballots[ballotCount].end = block.timestamp + duration;

        for(uint i = 0;i < _proposals.length; i++) {
            ballots[ballotCount].proposals.push(Proposal(i, _proposals[i], 0));
        }
    }

    function vote(uint ballotId, uint proposalId) public {
        require(voters[ballotId][msg.sender].canVote == 0, 'Voter cannot voter');
        require(votes[ballotId] [msg.sender]== false, 'Voter has already cast the vote');
        require(block.timestamp < ballots[ballotId].end, 'Voting has ended');
        votes[ballotId][msg.sender] = true;
        ballots[ballotId].proposals[proposalId].votes++;
        voters[ballotId][msg.sender].vote = proposalId;
    }

/*
    function delegate(uint ballotId, address _delegateAddress) public {
        Voter storage _voter = voters[ballotId][msg.sender];
        require(!_voter.voted, 'Voter has already cast the vote');
        require(_delegateAddress != msg.sender, 'Voter and delegate address are same');

        _voter.voted = true;
        _voter.delegate = _delegateAddress;

        Voter storage _delegated = voters[ballotId][_delegateAddress];

        if(_delegated.voted) {
            ballots[ballotId][_delegated.vote].votes++;
        } else {
            _delegated.canVote++;
        }
    } */

    function results(uint ballotId) public  returns(Proposal[] memory proposals) {
        require(ballots[ballotId].end <= block.timestamp, 'Voting has not ended');
        return ballots[ballotId].proposals;
    }

    function getResultName(uint ballotId) public returns (string memory _name) {
        uint voteCount = 0;
        Ballot storage _ballot = ballots[ballotId];

        for(uint i = 0;i < _ballot.proposals.length;i++) {
            if(_ballot.proposals[i].votes > voteCount) {
                voteCount = _ballot.proposals[i].votes;
                _name = _ballot.proposals[i].name;
            }
        }
    }
}























