// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PollACLv1, ProposalId} from "./Types.sol"; // solhint-disable-line no-global-import

// Simple ACL where anyone can create a poll, manage any poll and cast vote.
// This ACL should be used for TESTING AND DEMONSTRATION PURPOSES ONLY!
//
// ACL rules:
// - anyone can create a poll
// - anyone can manage and close the poll
// - anyone can vote on any ballot
contract AllowAllACLv1 is PollACLv1 {
    function canCreatePoll(address, address)
        external pure
        returns(bool)
    {
        // Anyone can create a poll
        return true;
    }

    function onPollCreated(address dao, ProposalId proposalId, address creator)
    external
    {
        // Do nothing
    }

    function canManagePoll(address, ProposalId, address)
        external pure
        returns(bool)
    {
        // Anyone can manage any poll
        return true;
    }

    function canVoteOnPoll(address, ProposalId, address)
        external pure
        returns(bool)
    {
        // Anyone can vote on any poll
        return true;
    }
}
