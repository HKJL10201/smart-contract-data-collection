pragma solidity ^0.5.0;

import "./Pausable.sol";

/**
                        ██████           ██        ██          ██               ██      ████████████
                        ██   ██        ██  ██      ██          ██            ██    ██        ██
                        ██████        ██    ██     ██          ██           ██      ██       ██
                        ██   ███     ██████████    ██          ██           ██      ██       ██
                        ██     ██   ██        ██   ██          ██            ██    ██        ██
                        ████████   ██          ██  ██████████  ██████████       ██           ██

 * @title Voting to select which piture is better.
 * @author Yang Han, Lee.c, Skyge 
 */

contract Ballot is Pausable {
    // It will represent a single voter.
    struct Voter {
        bool hasVoted;      // if true, that person already voted
        uint8 voteFor;      // index of the voted proposal
    }

    // This is a type for a single proposal.
    struct Proposal {
        uint8 id;           // number of proposal
        uint32 voteCount;   // number of accumulated votes
    }

    // This declares a state variable that
    // stores a `Voter` struct for each possible address.
    mapping(address => Voter) public voters;

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    // voted event
    event VotingEvent (uint indexed _candidateId);

    /// @dev Create a new ballot to choose one of `proposalNumbers`.
    constructor(uint8 proposalNumbers) public {
        // For each of the provided proposal names,
        // create a new proposal object and add it
        // to the end of the array.
        for (uint8 i = 0; i < proposalNumbers; i++) {
            proposals.push(Proposal({
                id: i,
                voteCount: 0
            }));
        }
    }

    /// @dev Give your vote 
    /// to proposal `proposals[proposal].id`. 
    /// Only valid when contract does not pause.
    function vote(uint8 proposal) public whenNotPaused returns (bool) {
        Voter storage sender = voters[msg.sender];
        require(!sender.hasVoted, "Already voted.");
        require(proposal <= proposals.length-1, "Please check your voting number!");
        sender.hasVoted = true;
        sender.voteFor = proposal;

        // If `proposal` is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += 1;

        // trigger voting event
        emit VotingEvent(proposal);

        return true;
    }

    /// @dev Add a new candidate, but only for the owner.
    function addCandidate() public onlyOwner returns (bool) {
        proposals.push(Proposal({
            id: uint8(proposals.length),
            voteCount: 0
        }));

        return true;
    }

    /// @dev Get the length of the array of `proposals`.
    function proposalsCount() public view returns (uint256) {
        return proposals.length;
    }
}
