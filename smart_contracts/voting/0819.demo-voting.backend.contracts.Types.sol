// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

type ProposalId is bytes32;

struct ProposalParams {
    string ipfsHash;
    uint16 numChoices;
    bool publishVotes;
}

/**
 * @title Generic ACL interface for DAO polls.
 *
 * Write functions for setting actual permissions are not part of this
 * interface and should be specific to ACL implementations and specific dApp.
 */
interface PollACLv1 {
    error ACLManagementNotAllowed();
    error PollCreationNotAllowed();
    error PollManagementNotAllowed();
    error VoteNotAllowed();

    // Can a given user create a new poll.
    function canCreatePoll(address dao, address user) external view returns(bool);

    // DAO callback function when a new poll was created. This is typically invoked
    // to assign poll creator as its manager.
    function onPollCreated(address dao, ProposalId proposalId, address creator) external;

    // Can a given user manage poll (e.g. close the poll, add eligible voters).
    function canManagePoll(address dao, ProposalId proposalId, address user) external view returns(bool);

    // Is a given user eligible voter for the given poll.
    function canVoteOnPoll(address dao, ProposalId proposalId, address user) external view returns(bool);
}

interface AcceptsProxyVotes {
    function createProposal(ProposalParams calldata _params) external returns (ProposalId);
    function proxyVote(address voter, ProposalId proposalId, uint256 choiceIdBig) external;
    function getACL() external view returns (PollACLv1);
}
