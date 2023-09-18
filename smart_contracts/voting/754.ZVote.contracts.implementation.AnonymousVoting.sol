// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./TicketSpender.sol";
import "../interfaces/IAnonymousVoting.sol";

struct VotingPeriod {
    uint256 start;
    uint256 end;
}

struct Winner {
    uint256 option;
    uint256 votes;
}

/**
 * @title - Anonymous Voting contract
 * @notice A contract that allows for anonymous
 *  voting between a fixed addresses, given at contract
 *  initialization. Every vote is seen publicly, but the
 *  issuer is not revealed.
 */
contract AnonymousVoting is IAnonymousVoting, TicketSpender {
    // registered elections
    mapping(uint256 => bool) election;
    
    // election configuration
    mapping(uint256 => address[]) public voters;
    mapping(uint256 => VotingPeriod) votingPeriod;
    // election ticket storage
    mapping(uint256 => uint256[]) public tickets;
    // election internal ticket requirements
    mapping(uint256 => mapping(address => bool)) internal registered;
    mapping(uint256 => mapping(uint256 => bool)) internal nullified;

    // votes indexed by (electionId, MerkleRoot, option)
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) internal votes;
    // winner indexed by (electionId, MerkleRoot)
    mapping(uint256 => mapping(uint256 => Winner)) public winner;

    // merkle root by election (ideally unique)
    mapping(uint256 => uint256) merkleRoots;
    mapping(uint256 => bool) sameRoots;

    modifier beforeVotingPeriod(uint256 electionId) {
        require(
            block.timestamp < votingPeriod[electionId].start,
            "should be before the voting period");
        _;
    }
    modifier duringVotingPeriod(uint256 electionId) {
        VotingPeriod memory electionVotingPeriod = votingPeriod[electionId];
        require(
            block.timestamp >= electionVotingPeriod.start && 
            block.timestamp < electionVotingPeriod.end,
            "should be inside the voting period");
        _;
    }

    modifier afterVotingPeriod(uint256 electionId) {
        require(
            block.timestamp > votingPeriod[electionId].end,
            "should be after the voting period");
        _;
    }

    modifier onlyVoters(uint256 electionId) {
        address[] memory electionVoters = voters[electionId];
        bool inside = false;
        for (uint256 i = 0; i < electionVoters.length; i++) 
            if (msg.sender == electionVoters[i]) {
                inside = true;
                break;
            }
        require(inside, "sender has to be registered as a voter");
        _;
    }

    function registerElection(
        uint256 electionId,
        address[] memory _voters, 
        uint256 start, uint256 end
    ) external override {
        require(!election[electionId], "election already registered");
        election[electionId] = true;
        voters[electionId] = _voters;
        votingPeriod[electionId] = VotingPeriod(start, end);
    }
    
    function registerTicket(
        uint256 electionId, uint256 ticket
    ) beforeVotingPeriod(electionId) onlyVoters(electionId) 
    external override {
        require(election[electionId], "election not registered");
        require(
            !registered[electionId][msg.sender], 
            "voter already registered ticket");
        registered[electionId][msg.sender] = true;
        tickets[electionId].push(ticket);
    }

    function spendTicket(
        uint256 electionId, uint256 merkleRoot,
        uint256 option, uint256 serial, bytes memory proof
    ) duringVotingPeriod(electionId) external override {
        require(election[electionId], "election not registered");
        require(!nullified[electionId][serial], "ticket already spent");
        bool result = this.verifyTicketSpending(
            option, serial, merkleRoot, proof);
        require(result == true, "incorrect proof");
        nullified[electionId][serial] = true;
        votes[electionId][merkleRoot][option]++;
        // assign election winner by the used merkle root
        uint256 optionVotes = votes[electionId][merkleRoot][option];
        if (optionVotes > winner[electionId][merkleRoot].votes) {
            winner[electionId][merkleRoot].option = option;
            winner[electionId][merkleRoot].votes = optionVotes;
        }
    }

    function getWinner(
        uint256 electionId, uint256 _merkleRoot
    ) afterVotingPeriod(electionId)
    external view override returns (uint256) {
        require(election[electionId], "election not registered");
        return winner[electionId][_merkleRoot].option;
    }

    /**
     * @notice Allows users to fetch tickets and build
     *   their own Merkle tree, so they can construct 
     *   their Merkle proof locally
     */
    function getTickets(
        uint256 electionId
    ) external view override returns (uint256[] memory) {
        return tickets[electionId];
    }
}