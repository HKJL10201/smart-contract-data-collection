// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

// @title Voting with delegation.
contract Ballot {
  // This declares a new complex type which will
  // be used for variables later.
  // It will represent a single voter.

  struct Voter {
    uint weight; // weight is accumulated by delegation
    bool voted; // if true, that person already voted
    address delegate; // person delegated to
    uint vote; // index of the voted proposal
  }

  // This is a type for a single proposal
  struct Proposal {
    // If you can limit the length to a certain number of bytes,
    // always use one of bytes1 to bytes32 because they are much cheaper
    bytes32 name; // short name (up to 32 bytes)
    uint voteCount; // number of accumulated votes
  }

  address public chairperson;

  // This declares a state variable that stores 
  // a 'Voter' struct for each possible address.
  mapping(address => Voter) public voters;

  // A dynamically-sized array of 'Proposal' structs.
  Proposal[] public proposals;

  // Create a new ballot to choose one of 'proposalNames'.
  constructor(bytes32[] memory proposalNames) {
    chairperson = msg.sender;
    voters[chairperson].weight = 1;

    // For each of the provided proposal names,
    // create a new proposal object and add
    // to the end of the array
    for (uint i = 0; i < proposalNames.length; i++) {
      proposals.push(Proposal({name: proposalNames[i], voteCount: 0}))
    }
  }

  /**
    * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'
  */
    function giveRightToVote(address voter) public {
      require(msg.sender == chairperson, 'Only chairperson can give right to vote.');
      require(!voters[voter].voted, "The voter has already voted");

      require(voter[voter].weight == 0);
      voter[voter].weight = 1;
    }

    // Delegate your vote to the voter 'to'
    // to address to which vote is delegated
    function delegate(address to) public {
      Voter storage sender = voters[msg.sender];
      require(!sender.voted, 'You already voted'); 
      
      require(to != msg.sender, 'You cannot delegate your vote to yourself');

      // Forward delegation as long as 'to' also delegated
      while(voters[to].delegate != address(0)) { // is not empty address
        to = voters[to].delegate; // delegate to the address that 'to' delegated to

        // We found a loop in the delegation, not allowed.
        require(to != msg.senderm 'Found loop in delegation');
      }
      

      // Since sender is a reference, this modifies 'voters[msg.sender].voted'
      sender.voted = true;
      sender.delegate = to;
      Voter storage delegate_ = voters[to];
      if(delegate_.voted) {
        // If the delegate already voted,
        // directly add to the number of votes
        proposals[delegate_.vote].voteCount += sender.weight;
      } else {
        // If the delegate did not vote yet, add to her weight
        delegate_.weight += sender.weight;
      }
    }

    // Give your vote (including votes delegated to you) to propos 'proposals[proposal].name'
   function vote(uint proposal) public {
     Voter storage sender = voters[msg.sender];
     require(sender.weight != 0, 'Has no right to vote');
     require(!sender.voted, 'You already voted');

     sender.voted = true;
     sender.vote = proposal;
e
     // If 'proposal' is out of the range of the array,
     // this will throw automatically and revert all changes
     proposals[proposal].voteCount += sender.weight;
   }
   
   // Computes the winning proposal taking all previous votes into account.
   function winningProposal() public view returns (uint winningProposal_) {
     uint winningVoteCount = 0;
     for (uint p = 0; p < proposals.length; p++) {
       if (proposals[p].voteCount > winningVoteCount) {
         winningVoteCount = proposals[p].voteCount;
         winningProposal_ = p;
       }
     }
   }
   
   // Calls winningProposal() function to get the index of the winned contained
   // in the proposals array and then returns the name of the winner
   function winnerName() public view returns (bytes32 winnerName_) {
     winnerName_ = proposals[winningProposal()].name;
   }
}
