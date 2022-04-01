// Based on an example contract in the Solidity documentation
// https://docs.soliditylang.org/en/v0.8.6/solidity-by-example.html#voting

pragma solidity >=0.4.22 <0.8.0;

contract Ballot {

    struct Voter {
        address delegate;
        uint weight;
        bool voted;
        uint vote;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    Proposal[] public proposals;
    address public chairperson;

    mapping(address => Voter) public voters;


    constructor(bytes32[] memory _proposalNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint256 i = 0; i < _proposalNames.length; i++) {
            proposals.push(Proposal({ 
                name:_proposalNames[i], 
                voteCount:0 
            }));
        }
    }

    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only chairperson can give right to vote.");
        require(!voters[voter].voted, "The voter has already voted");
        require(voters[voter].weight == 0, "The voter has no right to vote.");

        voters[voter].weight = 1;
    }

    function delegate(address delegateAddress) public {
        Voter storage sender = voters[msg.sender];

        require(!sender.voted, "You already voted.");
        require(msg.sender != delegateAddress, "Self-delegate is not allowed.");

        while (voters[delegateAddress].delegate != address(0)) {
            delegateAddress = voters[delegateAddress].delegate;
            require(msg.sender != delegateAddress, "Found loop in delegation.");
        }

        sender.delegate = delegateAddress;
        sender.voted = true;

        voters[delegateAddress].weight += sender.weight;
    }

    function vote(uint proposalId) public {
        Voter storage voter = voters[msg.sender];
        require(voter.weight > 0, "Has no right to vote.");
        require(!voter.voted, "Already voted.");

        proposals[proposalId].voteCount += voter.weight;
        voter.voted = true;
        voter.vote = proposalId;
    }

    function winningProposal() public view returns(uint256 winningProposalIndex) {
        uint winningVoteCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[winningProposalIndex].voteCount;
                winningProposalIndex = i;
            }
        }
    }

    function winnerName() public view returns (bytes32 _winnerName) {
        _winnerName = proposals[winningProposal()].name;
    }
}
