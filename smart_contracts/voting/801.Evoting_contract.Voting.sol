// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title A contract for Voting 
 * @dev Implements voting process along with vote delegation
 */
contract Voting {
    uint NumberOfCandidates;
    struct Voter{
        uint weight; // weight is accumulated by delegation or if they have right to vote
        bool voted;  // if true, that person already vote
        uint vote;   // index of the voted proposal
    }

    struct Candidate{
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;//chairperson of Election Commision of India 

    mapping(address => Voter) public voters;

    mapping(uint => Candidate) public candidates;

    
    constructor() {
        chairperson = msg.sender;//whoever deploys the contract , the constructor stores it
        voters[chairperson].weight = 1;
    }

    
    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    function addCandidate(string memory proposalNames) public{ 
        require(msg.sender == chairperson);//Election Commision will allot the name 
        uint id =  0;
        NumberOfCandidates = 1;
        candidates[id].name = proposalNames;
        candidates[id].voteCount = 0;
        id++;
        NumberOfCandidates++;

    }
    
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

 /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        candidates[proposal].voteCount += sender.weight;// short form in for ++;
    }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningCandidate() public view returns (uint)
    {
        uint winningVoteCount = 0;
        uint temp;
        for (uint p = 0; p < NumberOfCandidates; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                temp = p;
            }
        }
        return temp;
    }

    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = candidates[winningCandidate()].name;
    }
}
