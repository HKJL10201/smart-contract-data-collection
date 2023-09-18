pragma solidity ^0.4.0;

/// @title Voting with delegation.
contract Ballot {
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.

    // This is a type for a single proposal.
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;
    string winner = 'none';

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => bool) public voted;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    /// Create a new ballot to choose one of `proposalNames`.
    function Ballot() payable {
        chairperson = msg.sender;

        // `Proposal({...})` creates a temporary
        // Proposal object and `proposals.push(...)`
        // appends it to the end of `proposals`.
        proposals.push(Proposal({
            name: 'YES',
            voteCount: 0
				}));

				proposals.push(Proposal({
						name: 'NO',
						voteCount: 0
        }));

				proposals.push(Proposal({
						name: 'TIED',
						voteCount: 0
        }));
    }

    function initialize(address test) payable {
      /*if(msg.sender == chairperson) {*/
        voted[msg.sender] = false;
      /*}*/
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    function vote(uint proposal) payable {
        if (voted[msg.sender] == false) {
        	voted[msg.sender] = true;
					proposals[proposal].voteCount += 1;
				}
    }

    function checkVoted() constant returns(bool) {
      return voted[msg.sender];
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() payable {
      if (proposals[0].voteCount > proposals[1].voteCount) {
        winner = proposals[0].name;
      } else {
				if (proposals[0].voteCount < proposals[1].voteCount) {
          winner = proposals[1].name;
			  } else {
          winner = proposals[2].name;
			  }
			}
    }

    function winnerName() constant returns (string) {
        return winner;
    }
}
