// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Voting
 * @dev implement voting functions
 */
contract Voting {

    struct Voter{
        uint256 weight;
        bool voted;
        uint256 vote;  // index of the voted proposal
        uint256 rewards; // used to store points rewarded to address that has voted
    }

    struct Proposal{
        bytes32 title; // short title(up to 32 bytes)
        string descriptions;
        uint256 voteCount; // number of accumulated votes
    }

    enum State { NotStarted,OnGoing, Ended } // state of the voting contract

    State public state;
    address public admin;
    mapping (address => Voter) public voters; 
    Proposal[] public proposals;
    address[] public votersAddresses; // addresses already voted

    error NotAdmin(); 
    error HasBeenAuthorized();
    error AlreadyVoted();
    error NoRightToVote();
    error NotOnGoing();
    error NotEnded(); // custom errors without using "require"
    
    modifier onlyAdmin {
        // require(msg.sender == admin, "Only admin can call this function.");
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

/**
 * @dev initiate votings by adding the title and descriptions of proposals
 * @param proposalInputs array of structs holding information on proposals
 */   
    constructor(Proposal[] memory proposalInputs) {
        admin = msg.sender;
        voters[admin].weight = 1;
        state = State.OnGoing;

        for(uint256 i = 0; i < proposalInputs.length; i++) {
            proposals.push(Proposal(proposalInputs[i].title, proposalInputs[i].descriptions, 0));
        }
    }

/**
 * @dev Give 'voter' the right to vote for specific proposals. May only be called by 'admin'.
 */
    function giveRightToVote(address voter) public onlyAdmin {
        if (state != State.OnGoing) revert NotOnGoing();
        if (voters[voter].voted) revert AlreadyVoted();
        if (voters[voter].weight != 0) revert HasBeenAuthorized();
        // require(state == State.OnGoing, "It's not in voting period.");
        // require(!voters[voter].voted, "Already voted.");
        // require(voters[voter].weight == 0, "Address has been authorized to vote.");
        voters[voter].weight = 1;
    }
/**
 * @dev eligible voters vote to proposal 'proposals[proposal].title'
 * @param proposal index of proposal in the proposals array
 */
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        if (state != State.OnGoing) revert NotOnGoing();
        if (sender.weight == 0) revert NoRightToVote();
        if (sender.voted) revert AlreadyVoted();
        // require(state == State.OnGoing, "It's not in voting period.");
        // require(sender.weight != 0, "Has no right to vote.");
        // require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        sender.rewards += 5;
        votersAddresses.push(msg.sender);

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += sender.weight;
    }

/**
 * @dev reset all the previous voting information, and end voting forcefully.
 */
    function resetVoting() public onlyAdmin {
        // require(state == State.OnGoing, "It's not in voting period.");
        if (state != State.OnGoing) revert NotOnGoing();
        delete proposals;
        for (uint256 i = 0; i < votersAddresses.length; i++) {
            delete voters[votersAddresses[i]];
        }
        delete votersAddresses;
        state = State.NotStarted;
    }

/**
 * @dev to end the voting period. May only be called in voting period
 */
    function endVoting() public onlyAdmin {
        // require(state == State.OnGoing, "It's not in voting period.");
        if (state != State.OnGoing) revert NotOnGoing();
        state = State.Ended;
    }

/**
 * @dev Computes the winning proposal by taking all previous votes into account and get the index of the winner in the proposals array then
 * @return winnerProposalTitle_  the title of the winner
 */
    function winnerProposalTitle() public view returns (bytes32 winnerProposalTitle_){
        // require(state == State.Ended, "It's not in the ended period.");
        if (state != State.Ended) revert NotEnded();
        uint winningVoteCount;
        uint winningProposal;  // index of the wining proposal in proposals array

        for (uint i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal =i;
            }
        }

        winnerProposalTitle_ = proposals[winningProposal].title;
    }

/**
 * @dev Check if an address has already been voted
 * @return hasVoted_ boolean value representing if a vote has been cast
 */
    function hasVoted(address voter) public view returns (bool hasVoted_) {
        hasVoted_ = voters[voter].voted;
    }
}