// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// modifier, owner is the deployer
error Ballot__NotOwner();

contract Ballot {
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
        address delegate; // person delegated to
        uint[] vote; // index of the voted proposal
    }

    struct Proposal {
        // If you can limit the length to a certain number of bytes,
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name; // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // storage
    address private immutable chairperson;
    // always check voters[addr].weight if 0 to tell if the voter could vote
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    uint[][] votes;
    uint[] votecounts;

    // Modifiers: Modifiers can also be chained together, meaning that you can have
    // multiple modifiers on a single function. However, modifiers can only modify
    // contract logic, and they cannot modify a contract’s storage
    modifier onlyOwner() {
        if (msg.sender != chairperson) revert Ballot__NotOwner();
        _;
    }

    function stringToBytes32(
        string memory source
    ) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    //constructor(bytes32[] memory proposalNames) {
    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            proposals.push(
                Proposal({
                    name: stringToBytes32(proposalNames[i]),
                    voteCount: 0
                })
            );
        }
    }

    /**
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public onlyOwner {
        require(voters[voter].weight == 0, "The voter could vote already.");
        voters[voter].weight = 1;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "has no right to vote/delegate.");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        // QUESTION: what if the person getting the delegated vote has no right to
        // vote? does this need to be handled?
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            uint voteIndex = findVote(delegate_.vote);
            votecounts[voteIndex] += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     * @param proposals_ the voting sequence
     */
    function vote(uint[] memory proposals_) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposals_;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        uint voteIndex = findVote(proposals_);
        if(voteIndex != votes.length+1){
            votecounts[voteIndex] += sender.weight;
        } else {
            votes.push(proposals_);
            votecounts.push(sender.weight);
        }
    }

    function findVote(uint[] memory proposals_) private view returns (uint){
        for(uint j = 0; j < votes.length; j++){
            bool mismatch = false;
            for(uint i = 0; i < votes[j].length; i++){
                if(votes[j][i] != proposals_[i]){
                    mismatch = true;
                    break;
                }
            }
            if(!mismatch){
                return j;
            }
        }
        return votes.length+1;
    }

    /**
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() public view returns (uint winningProposal_) {
        bool[] memory inRunning = new bool[](proposals.length);
        Proposal[] memory proposals_ = proposals;
        for(uint i = 0; i < proposals.length; i++){
            inRunning[i] = true;
        }
        uint count = 0;
        while(count < proposals_.length-1){
            for(uint i = 0; i < votes.length; i++){
                for(uint j = 0; j < votes[i].length; j++){
                    if(inRunning[votes[i][j]]){
                        proposals_[votes[i][j]].voteCount += votecounts[i]; //tallys up the # of first place votes for each choice
                        break;
                    }
                }
            }
            uint losingVoteCount = 1000;
            for(uint i = 0; i < proposals_.length; i++){
                if(proposals_[i].voteCount < losingVoteCount && inRunning[i]){
                    losingVoteCount = proposals[i].voteCount; //looks for proposal with least votes
                }
            }
            for(uint i = 0; i < proposals_.length; i++){
                if(proposals_[i].voteCount == losingVoteCount){
                    count++;
                    inRunning[i] = false; //if proposal has least # of votes, it is no longer in contention
                }
            }

            for(uint i = 0; i < proposals_.length; i++){
                proposals_[i].voteCount = 0; //resets all votes
            }
            bool flag = false;
            for(uint i = 0; i < proposals_.length; i++){
                if(inRunning[i]){
                    flag = true;
                }
            }
            if(flag == false){
                return proposals_.length; //tie edgecase
            }
        }
        for(uint i = 0; i < inRunning.length; i++){
            if(inRunning[i]){
                return i;
            }
        }
    }

    /**
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view returns (bytes32 winnerName_) {
        uint winning = winningProposal();
        if(winning == proposals.length){
            return "Tie";
        }
        winnerName_ = proposals[winning].name;
    }

    function getProposalName(
        uint256 index
    ) public view returns (bytes32 option_) {
        require(index < proposals.length, "Invalid proposal index.");
        option_ = proposals[index].name;
    }

    function getUniqueVoteCount() public view returns (uint256 count_) {
        count_ = votes.length;
    }

    function getVoteDetail(
        uint256 index
    ) public view returns (uint[] memory option_) {
        require(index < votes.length, "Invalid vote index.");
        option_ = votes[index];
    }

    function getVoteCountByIndex(
        uint256 index
    ) public view returns (uint256 option_) {
        require(index < votes.length, "Invalid vote index.");
        option_ = votecounts[index];
    }

    function getProposalVote(uint[] memory proposals_) public view returns (uint count_) {
        uint voteIndex = findVote(proposals_);
        if(voteIndex != votes.length+1){
            return votecounts[voteIndex];
        } else {
            return 0;
        }
    }

    function ifVoted() public view returns (bool ifVote_) {
        ifVote_ = voters[msg.sender].voted;
    }

    function getWeight(
        address addr
    ) public view onlyOwner returns (uint weight_) {
        weight_ = voters[addr].weight;
    }

    function getVoterInfo(
        address addr
    ) public view onlyOwner returns (Voter memory voter_) {
        voter_ = voters[addr];
    }

    function getVotesByProposalAndRank(uint256 index1, uint256 index2) public view returns (uint256 votes__){
        for(uint i = 0; i < votes.length; i++){
            if(votes[i][index2] == index1){
                votes__++;
            }
        }
    }
}
