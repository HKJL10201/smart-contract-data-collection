//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Smart-contract for votings 
/// @author Appaev Timur 
/// @notice Avoid using this, it has limitations and isn't solid
contract Votings is Ownable, AccessControl {

    struct Voting {
        uint32 activeUntil; // + 900 seconds tolerance, will work till Sun Feb 07 2106
        uint32 maxVotes;
        uint32 totalVotes;
        bool notPaidYet;
        // 152 bits left

        mapping(address => uint32) votes;
        mapping(address => bool) voters;
        address payable [] participantsAddresses;
    }

    mapping(bytes32 => Voting) votings;

    bytes32 public constant VOTING_ADMIN_ROLE = keccak256("VOTING_ADMIN_ROLE");
    uint256 public constant VOTE_AMOUNT = 0.01 ether;
    uint256 public constant VOTE_PRIZE  = 0.009 ether;
    uint256 public constant VOTE_FEE    = 0.001 ether;
    uint32 public DURATION_OF_VOTING_IN_SECONDS; //  should be 3 days;

    uint256 feeAmount;

    /// @param duration The duration of the voting in seconds
    constructor(uint32 duration) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        DURATION_OF_VOTING_IN_SECONDS = duration;
    }

    // we use some hash (depends on which hash algorithm was picked by dapp designer)
    // of voting's description as voting name
    // this allows us make description as long as we want and distribute it to users without using blockchain
    // dapp always can verify accordance between description and votingName just by recalculating hash of description

    /// @param votingName Hash of the voting's description
    /// @param participantsAddresses Array of participants addresses
    function startVoting(bytes32 votingName, address payable [] calldata participantsAddresses) public {
        Voting storage currVoting = votings[votingName];
       
        require(hasRole(VOTING_ADMIN_ROLE, msg.sender), "Caller is not an admin"); // c2
        require(participantsAddresses.length > 1, "There must be at least two participants"); // c3
        require(currVoting.activeUntil == 0, "The voting already started"); // c4
       
        currVoting.activeUntil = uint32(block.timestamp) + DURATION_OF_VOTING_IN_SECONDS; // till Sun Feb 07 2106
       
        currVoting.participantsAddresses = participantsAddresses;
        currVoting.notPaidYet = true;
        currVoting.maxVotes = 1;
        for (uint32 i = 0; i < participantsAddresses.length; i++) {
            // yep, it's safe because we use it only to compare with others participants
            currVoting.votes[participantsAddresses[i]] = 1;
        }
    }

    /// @param votingName Hash of the voting's description
    /// @param participant Voted participant
    function vote(bytes32 votingName, address participant) payable public {
        Voting storage currVoting = votings[votingName];
       
        require(msg.value == VOTE_AMOUNT, "You have to send 0.01 ether for voting"); // v3, v4
        require(currVoting.activeUntil > block.timestamp, "There is no such active voting"); // v5, v6
        require(currVoting.votes[participant] != 0, "There is no such participant in the voting"); // v7
        require(!currVoting.voters[msg.sender], "You can vote only once"); // v2
       
        currVoting.votes[participant] += 1;
        currVoting.totalVotes += 1;
        currVoting.voters[msg.sender] = true;

        if ((currVoting.votes[participant]) > currVoting.maxVotes) {
            currVoting.maxVotes = currVoting.votes[participant];
        }

    }


    /// @param votingName Hash of the voting's description
    function finishVoting(bytes32 votingName) public {
        Voting storage currVoting = votings[votingName];
 
        require(currVoting.activeUntil != 0, "There is no such active voting"); // f3
        require(currVoting.activeUntil < block.timestamp, "Voting is still active"); // f1
        require(currVoting.notPaidYet, "Voting is already finished"); // f4
        currVoting.notPaidYet = false; // f4
        feeAmount += currVoting.totalVotes * VOTE_FEE; // f2c
 
        uint32 winnersCount;
        if (currVoting.totalVotes != 0) { // f2
            address payable [] memory winners = new address payable [](currVoting.participantsAddresses.length);
            for (uint32 i = 0; i < currVoting.participantsAddresses.length; i++) {
                address payable participant = currVoting.participantsAddresses[i];
                if ((currVoting.votes[participant]) == currVoting.maxVotes) {
                    winners[winnersCount] = participant;
                    winnersCount++;
                }
            }
           
            uint256 totalPrize = currVoting.totalVotes * VOTE_PRIZE;
            uint256 onePeace = totalPrize / winnersCount; // it's safe, we always have at least one winner
            uint256 rest = totalPrize - onePeace * winnersCount;
            if (rest != 0) {
                feeAmount += rest; // f2c
            }
            for (uint32 i = 0; i < winnersCount; i++) {
                if (!isContract(winners[i])) {
                    if (!winners[i].send(onePeace)) {
                      // TODO 
                    }
                } else {
                    // TODO
                }
            }
        }
    }

    function withdraw () onlyOwner public { // w3
        require(feeAmount != 0, "There is nothing to withdraw"); // w2, w4
        uint256 amount = feeAmount;
        // TODO if we leave 1 wei instead of withdraw all currency we can make it more predictable gas-spending wise
        feeAmount = 0;
        if (!payable(msg.sender).send(amount)) {
            // TODO
        }
    }

    /* views */

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function getActiveUntil (bytes32 votingName) public view returns (uint32) {
        return votings[votingName].activeUntil;
    }

    function getVotes (bytes32 votingName, address participant) public view returns (uint32) {
        return votings[votingName].votes[participant] - 1; // see startVoting
    }

    function getFeeAmount () public view returns (uint256) {
        return feeAmount; // see startVoting
    }
}
