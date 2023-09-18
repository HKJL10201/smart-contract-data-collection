// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    struct Voter {
        uint weight;
        bool voted;
        uint8 vote;
        // address delegate;
    }

    //modifer
    modifier onlyOwner () {
      require(msg.sender == chairperson,
      "Only chairperson can give right to vote."
      );
      _;
    }

    /* struct Proposal {
        uint voteCount; // could add other data about proposal
    } */
    address public chairperson;
    mapping(address => Voter) public voters;
    uint[4] public proposals;

    event votedEvent(string messageVoted, address _voter);
    event registeredEvent(string messageRegistered);

    // Create a new ballot with 4 different proposals.
    constructor() {
        chairperson = msg.sender;
        voters[chairperson].weight = 2;
    }

    /// Give $(toVoter) the right to vote on this ballot.
    /// May only be called by $(chairperson).
    function register(address toVoter) public onlyOwner{

        require(
            !voters[toVoter].voted,
            "The voter already voted."
        );
        require(
            voters[toVoter].weight == 0,
            "The voter is already registered."
        );

        voters[toVoter].weight = 1;
        voters[toVoter].voted = false;
        emit registeredEvent("Account registered");
    }

    /// Give a single vote to proposal $(toProposal).
    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        
        require(sender.weight != 0, "This account is not registered");
        require(!sender.voted, "This account has already voted");
            
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal] += sender.weight;
        emit votedEvent("Vote successfully cast by the account with address: ", msg.sender);
    }

    function winningProposal() public view returns (uint8 _winningProposal) {
        uint256 winningVoteCount = 0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop] > winningVoteCount) {
                winningVoteCount = proposals[prop];
                _winningProposal = prop;
            }
    }

    function getCount() public view returns (uint[4] memory) {
        return proposals;
    }
}
