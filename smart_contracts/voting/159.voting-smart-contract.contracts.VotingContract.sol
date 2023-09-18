pragma solidity ^0.8.0;

contract VotingContract {
    address public owner;
    uint public counter = 0;
    mapping(uint => Proposal) public proposals;

    constructor() {
        owner = msg.sender;
    }

    struct Proposal {
        string name;
        mapping(uint => Answer) answers;
        uint allVotesCount;
        bool ended;
    }

    struct Answer {
        string name;
        uint votesCount;
        address[] voters;
    }

    event Voted(address indexed _from, uint _proposalId, uint _vote);

    function NewProposal(string memory _name, string[] memory _answers, uint maxVotes) public payable {
        require(msg.sender==owner);
        require(maxVotes>=1);
        Proposal storage proposal = proposals[counter];
        proposal.name = _name;
        proposal.allVotesCount = maxVotes;
        proposal.ended = false;
        for (uint i=0; i < _answers.length; i++) {
            proposal.answers[i].name = _answers[i];
        }
        counter++;
    }

    function GetProposalInfo(uint id) public view returns(string memory, bool, Answer memory) {
        return (proposals[id].name, proposals[id].ended, proposals[id].answers[0]);
    }

    function EndProposal(uint id) internal {
        proposals[id].ended = true;
    }

    function VoteFor(uint proposalID, uint vote) public {
        require(proposals[proposalID].ended == false);
        Answer storage answer = proposals[proposalID].answers[vote];
        for (uint i=0; i < answer.voters.length; i++) {
            if (proposals[proposalID].answers[vote].voters[i]==msg.sender) {
                revert("You already vote");
            }
        }
        answer.voters.push(msg.sender);
        answer.votesCount++;
        proposals[proposalID].allVotesCount--;
        if (proposals[proposalID].allVotesCount == 0) {
            EndProposal(proposalID);
        }
        emit Voted(msg.sender, proposalID, vote);
    }

    function totalVotes(uint proposalID) public view returns(uint) {
        return (proposals[proposalID].allVotesCount);
    }
}