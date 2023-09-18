pragma solidity >=0.4.25 <0.7.0;

contract Ballot {

  struct Voter {
    bool voted;
    uint vote;
    uint weight; // Ability to vote
  }

  struct Proposal {
    // byte => basic unit measurement of information (less gas than string)
    bytes32 name; // name of each proposal
    uint voteCount; // number of accumulated vote
  }

// Voters get address as key and Voter for value
  Proposal[] public proposals;
  mapping(address => Voter) voters;

  address public chairman;

  constructor(bytes32[] memory proposalNames) public {
    // memory defines temporary data location in solidity during runtime only
    // we garantee spae for it

    chairman = msg.sender;

    // add proposalname to the smart contract upon deployment
    for(uint i = 0; i < proposalNames.length; i++) {
      proposals.push(Proposal({
        name: proposalNames[i],
        voteCount: 0
      }));
    }
  }

  // Authenticate voters
  function giveRightToVote(address voter) public {
    require(msg.sender == chairman, 'only chairman can give access to vote');
    require(!voters[voter].voted, 'The voter has already voted');
    
    // Check ability to vote
    require(voters[voter].weight == 0);

    voters[voter].weight = 1;
  }

  // Voting function
  // focus on each person sending a vote
  function vote(uint proposal) public {
    Voter storage sender = voters[msg.sender];
    require(sender.weight != 0, 'Has no right to vote');
    require(!sender.voted, 'Already voted');
    sender.voted = true;
    sender.vote = proposal;

    proposals[proposal].voteCount += sender.weight;
  }

  // Functions Showing the results

  // 1. Showing wining proposal by int
  function winningProposal() public view returns (uint winninProposal_) {
    uint winningVoteCount = 0;
    for(uint i = 0; i < proposals.length; i++){
      if(proposals[i].voteCount > winningVoteCount) {
        winningVoteCount = proposals[i].voteCount;
        winninProposal_ = i;
      }
    }
  }

  // 1. Showing winner by name
  function winningName() public view returns (bytes32 winningName_) {
   winningName_ =  proposals[winningProposal()].name;
  }

}