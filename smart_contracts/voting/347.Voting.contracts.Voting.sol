//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    // Voting fee of participant for vote
    uint constant public VOTING_FEE = 0.01 ether;

    // Duration of every vote is three days since vote creating
    uint32 constant public VOTE_DURATION = 3 days;

    // Fee from each vote pool that owner gets
    uint8 constant public FEE = 10; // 10%

    // Amount of available ether that owner can withdraw.
    // Owner gets fee from vote only at the end of vote.
    uint public availableEtherForWithdraw;

    struct Candidate {
        address addr;
        uint32 voteOf;
    }

    struct Vote {
        Candidate[] candidates;
        mapping(address => uint) candidateIndexes;
        string name;
        string description;
        uint pool;
        uint endTime;
        uint currentWinner;
        bool isEnded;
        address[] participants;
        mapping(address => bool) alreadyVoted;
    }

    Vote[] public votes;


    /*
        MODIFIERS
    */
    modifier voteIsExist(uint voteID) {
        require(voteID < votes.length, "Voting: vote with such ID doesn't exists");
        _;
    }


    /*
        EVENTS
    */

    /**
     * @dev Emitted when new vote is created by {createVote} function.
     */
    event VoteIsCreated(uint indexed voteID, string voteName, uint endTime);

    /**
     * @dev Emitted when th vote is ended by {endVote} function.
     */
    event VoteIsEnded(uint indexed voteID, address winner, uint winning);


    /*
        FUNCTIONS
    */

    /**
     * @dev Creates a new vote with `voteName` as name, `voteDeiscription` as
     * description and `candidateAddres` as list of candidates. end time of
     * vote is equal to the current timestamp plus three days. 
     *
     * Requirements:
     * - `voteName` can't be an empty;
     * - `candidateAddres` size must beat least 2;
     *
     * Note: `voteDescription` can be an empty if it unnecessary for you
     * IMPORTANT: the function doesn't check uniqueness of the voteName and
     * candidate addresses. It allows to create two votes with the same voteName.
     * Also you must not to send the equal candidate addresses in one vote!
     * Keep it in mind. 
     *
     * Emit an {VoteIsCreated} event.
     */
    function createVote(
        string calldata voteName,
        string calldata voteDescription,
        address[] calldata candidateAddrs
        )
        external
        onlyOwner
    {
        require(candidateAddrs.length > 1,
                "Voting: amount of candidates must be at least 2");
        require(bytes(voteName).length > 0,
                "Voting: voteName can't be an empty");

        Vote storage vote = votes.push();

        vote.name = voteName;
        vote.description = voteDescription;
        vote.endTime = block.timestamp + VOTE_DURATION;

        for (uint i = 0; i < candidateAddrs.length;) {
            address candidate = candidateAddrs[i];
            if (i > 0) {
                require(vote.candidates[0].addr != candidate &&
                        vote.candidateIndexes[candidate] == 0,
                            "Voting: candidate address must be an unique");
            }

            vote.candidates.push(Candidate(candidate, 0));
            vote.candidateIndexes[candidate] = i;
            unchecked { ++i; }
        }

        emit VoteIsCreated(votes.length - 1, voteName, vote.endTime);
    }

    /**
     * @dev Returns information about the vote by voteID.
     * The function returns:
     *  - list of candidates
     *  - list of participants
     *  - name of vote
     *  - description of vote
     *  - current pool of vote
     *  - current end time of vote
     *  - status of vote (is ended or not)
     *
     * Requirements:
     * - vote with `voteID` must be exists;
     */
    function getVote(uint voteID)
        external
        view
        voteIsExist(voteID)
        returns(
            string memory name,
            string memory description,
            Candidate[] memory candidates,
            Candidate memory currentWinner,
            address[] memory participants,
            uint pool,
            uint endTime,
            bool isEnded)
    {    
        Vote storage vote = votes[voteID];

        return (vote.name, vote.description, vote.candidates, vote.candidates[vote.currentWinner],
                vote.participants, vote.pool, vote.endTime, vote.isEnded);
    }

    /**
     * @dev Allows to participant to vote for candidate.
     *
     * Requirements:
     * - vote with `voteID` must be exists;
     * - candidate with `candidate` address must be exists;
     * - msg.value must be equal to {VOTING_FEE};
     * - vote must be an active;
     * - participant (msg.sender) can't vote twice;
     */
    function doVote(uint voteID, address candidate)
        external
        payable
        voteIsExist(voteID)
    {
        require(msg.value == VOTING_FEE,
                            "Voting: voting fee must be equal to 0.01 ether");

        Vote storage vote = votes[voteID];

        require(vote.endTime >= block.timestamp, "Voting: voting time is over");
        require(!vote.alreadyVoted[msg.sender], "Voting: you already has voted");
        uint candidateIndex = vote.candidateIndexes[candidate];
        if (candidateIndex == 0) {
            require(vote.candidates[0].addr == candidate,
                        "Voting: candidate with such address doesn't exists");
        }

        vote.pool += msg.value;
        ++vote.candidates[candidateIndex].voteOf;

        vote.alreadyVoted[msg.sender] = true;
        vote.participants.push(msg.sender);

        if (vote.candidates[candidateIndex].voteOf >
            vote.candidates[vote.currentWinner].voteOf)
        {
            vote.currentWinner = candidateIndex;
        }
    }


    /**
     * @dev Allows to end the vote with voteID. The Function automatically
     * transfer 90% of the winning to the winner.
     *
     * Requirements:
     * - vote with `voteID` must be exists;
     * - vote must not be already ended;
     * - vote must not be in processing (end time of the vote must be reached);
     *
     * Emit {VoteIsEnded} event. 
     */
    function endVote(uint voteID)
        external
        voteIsExist(voteID)
    {
        Vote storage vote = votes[voteID];

        require(vote.endTime < block.timestamp,
                                        "Voting: vote is still in the proccessing");
        require(!vote.isEnded, "Voting: vote is already ended");

        vote.isEnded = true;

        // 10% of the winning stays on the smart-contract
        uint voteFee = vote.pool / FEE;
        // The winner gets 90% of vote pool.
        uint winning = vote.pool - voteFee;

        availableEtherForWithdraw += voteFee;

        payable(vote.candidates[vote.currentWinner].addr).transfer(winning);

        emit VoteIsEnded(voteID, vote.candidates[vote.currentWinner].addr, winning);
    }

    /**
     * @dev Allows to withdraw available fee from the contract. Function must be
     * called only by owner of smart contract.
     *
     * Requirements:
     * - `amount` must be lower than or equal to the {availableEtherForWithdraw};
     *
     * Note: `amount` maybe be equal to zero. In such case function will be withdraw
     * all avaialable fee;
     */
    function withdrawAvailableFee(uint amount)
        external
        onlyOwner
    {
        amount = amount == 0 ? availableEtherForWithdraw : amount;
        require(availableEtherForWithdraw > 0 && amount <= availableEtherForWithdraw,
                "Voting: you don't have such amount of available fee for withdraw");

        availableEtherForWithdraw -= amount;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {
        availableEtherForWithdraw += msg.value;
    }
}
