// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PollACLv1, ProposalId} from "./Types.sol"; // solhint-disable-line no-global-import

// ACL rules:
// - anyone can create a poll
// - poll creator becomes poll manager
// - different poll managers can be set by the ACL owner
// - anyone can vote on any ballot
contract AllowVotersACLv1 is PollACLv1 {
    // Stores (dao, ProposalID, poll manager address) triplet.
    mapping (bytes32 => mapping(address => bool)) pollManagers;
    // Stores (dao, ProposalID) => list of poll managers in form of a list for
    // easier management.
    // Should be in sync with pollManagers.
    mapping (bytes32 => address[]) pollManagersList;

    // (dao, ProposalID, eligible voter address) triplet.
    mapping (bytes32 => mapping(address => bool)) eligibleVoters;
    // Stores (dao, ProposalID) => list of eligible voters in form of a list for
    // easier management.
    // Should be in sync with eligibleVoters.
    mapping (bytes32 => address[]) eligibleVotersList;

    address _owner;

    constructor() {
        _owner = msg.sender; // only DAO contract can change the contract.
    }

    function canCreatePoll(address, address) public pure returns(bool) {
        // Anyone can create a poll.
        return true;
    }

    function onPollCreated(address dao, ProposalId proposalId, address creator)
    external
    {
        if (msg.sender!=dao) revert ACLManagementNotAllowed();
        pollManagers[keccak256(abi.encode(dao, proposalId))][creator] = true;
    }

    function canManagePoll(address dao, ProposalId proposalId, address user) public view returns(bool) {
        return pollManagers[keccak256(abi.encode(dao, proposalId))][user] == true;
    }

    function setPollManagers(address dao, ProposalId proposalId, address[] calldata admins) public {
        if (msg.sender!=_owner) revert ACLManagementNotAllowed();

        mapping(address => bool) storage adminsMap = pollManagers[keccak256(abi.encode(dao, proposalId))];
        for (uint i=0; i<admins.length; i++) {
            adminsMap[admins[i]] = true;
        }
    }

    function canVoteOnPoll(address, ProposalId, address)
        external pure
        returns(bool)
    {
        return true;
    }

}
