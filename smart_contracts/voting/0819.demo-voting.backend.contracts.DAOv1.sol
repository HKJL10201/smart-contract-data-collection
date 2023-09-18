// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Types.sol"; // solhint-disable-line no-global-import
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import "./AllowAllACLv1.sol"; // solhint-disable-line no-global-import

contract DAOv1 is IERC165, AcceptsProxyVotes {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    error AlreadyExists();
    error NoChoices();
    error TooManyChoices();
    error NotPublishingVotes();
    error AlreadyVoted();
    error UnknownChoice();
    error NotActive();
    error StillActive();

    event ProposalCreated(ProposalId id);
    event ProposalClosed(ProposalId indexed id, uint256 topChoice);

    struct Proposal {
        bool active;
        ProposalParams params;
        uint8 topChoice;
    }

    struct ProposalWithId {
        ProposalId id;
        Proposal proposal;
    }

    struct Choice {
        bool exists;
        uint8 choice;
    }

    uint256 constant MAX_CHOICES = 32;

    struct Ballot {
        /// voter -> choice id
        mapping(address => Choice) votes;
        /// list of voters that submitted their vote
        address[] voters;
        /// choice id -> vote
        uint256[MAX_CHOICES] voteCounts;
    }

    // Confidential storage.
    mapping(ProposalId => Ballot) private _ballots;
    PollACLv1 private immutable acl;

    // Public storage.
    address public proxyVoter;
    mapping(ProposalId => Proposal) public proposals;
    EnumerableSet.Bytes32Set private activeProposals; // NB: Recursive structs cannot be public.
    ProposalId[] public pastProposals;

    constructor(PollACLv1 in_acl, address in_proxyVoter)
    {
        acl = (address(in_acl) == address(0)) ? new AllowAllACLv1() : in_acl;

        proxyVoter = in_proxyVoter;
    }

    function supportsInterface(bytes4 interfaceID)
        external pure
        returns (bool)
    {
        return interfaceID == 0x01ffc9a7                // ERC-165
            || interfaceID == this.castVote.selector    // DAOv1
            || interfaceID == this.proxyVote.selector;  // AcceptsProxyVotes
    }

    function getACL()
        external view
        returns (PollACLv1)
    {
        return acl;
    }

    function createProposal(ProposalParams calldata _params)
        external
        returns (ProposalId)
    {
        if (_params.numChoices == 0) revert NoChoices();
        if (_params.numChoices > MAX_CHOICES) revert TooManyChoices();
        if (!acl.canCreatePoll(address(this), msg.sender)) revert PollACLv1.PollCreationNotAllowed();

        bytes32 proposalHash = keccak256(abi.encode(msg.sender, _params));
        ProposalId proposalId = ProposalId.wrap(proposalHash);
        if (proposals[proposalId].active) revert AlreadyExists();

        proposals[proposalId] = Proposal({active: true, params:_params, topChoice:0});
        activeProposals.add(proposalHash);

        Ballot storage ballot = _ballots[proposalId];
        for (uint256 i; i < _params.numChoices; ++i)
        {
            ballot.voteCounts[i] = 1 << 255; // gas usage side-channel resistance.
        }

        acl.onPollCreated(address(this), proposalId, msg.sender);
        emit ProposalCreated(proposalId);
        return proposalId;
    }

    function getActiveProposals(uint256 _offset, uint256 _count)
        external view
        returns (ProposalWithId[] memory _proposals)
    {
        if (_offset + _count > activeProposals.length()) {
            _count = activeProposals.length() - _offset;
        }

        _proposals = new ProposalWithId[](_count);
        for (uint256 i; i < _count; ++i)
        {
            ProposalId id = ProposalId.wrap(activeProposals.at(_offset + i));
            _proposals[i] = ProposalWithId({id: id, proposal: proposals[id]});
        }
    }

    function internal_castVote(address voter, ProposalId proposalId, uint256 choiceIdBig)
        internal
    {
        if (!acl.canVoteOnPoll(address(this), proposalId, voter)) revert PollACLv1.VoteNotAllowed();

        Proposal storage proposal = proposals[proposalId];
        if (!proposal.active) revert NotActive();
        Ballot storage ballot = _ballots[proposalId];
        uint8 choiceId = uint8(choiceIdBig & 0xff);
        if (choiceId >= proposal.params.numChoices) revert UnknownChoice();
        Choice memory existingVote = ballot.votes[voter];

        // 1 click 1 vote.
        for (uint256 i; i < proposal.params.numChoices; ++i)
        {
            // read-modify-write all counts to make it harder to determine which one is chosen.
            ballot.voteCounts[i] ^= 1 << 255; // flip the top bit to constify gas usage a bit
            // Arithmetic is not guaranteed to be constant time, so this might still leak the choice to a highly motivated observer.
            ballot.voteCounts[i] += i == choiceId ? 1 : 0;
            ballot.voteCounts[i] -= existingVote.exists && existingVote.choice == i
            ? 1
            : 0;
        }

        if (proposal.params.publishVotes && !existingVote.exists)
        {
            ballot.voters.push(voter);
        }
        ballot.votes[voter].exists = true;
        ballot.votes[voter].choice = choiceId;
    }

    /**
     * Allow the designated proxy voting contract to vote on behalf of a voter
     */
    function proxyVote(address voter, ProposalId proposalId, uint256 choiceIdBig)
        external
    {
        require( msg.sender != address(0), "TX must be signed" );

        require( msg.sender == proxyVoter, "Cannot call proxyVote directly" );

        internal_castVote(voter, proposalId, choiceIdBig);
    }

    function castVote(ProposalId proposalId, uint256 choiceIdBig)
        external
    {
        internal_castVote(msg.sender, proposalId, choiceIdBig);
    }

    function getPastProposals(uint256 _offset, uint256 _count)
        external view
        returns (ProposalWithId[] memory _proposals)
    {
        if (_offset + _count > pastProposals.length) {
            _count = pastProposals.length - _offset;
        }

        _proposals = new ProposalWithId[](_count);

        for (uint256 i; i < _count; ++i)
        {
            ProposalId id = pastProposals[_offset + i];
            _proposals[i] = ProposalWithId({id: id, proposal: proposals[id]});
        }
    }

    function closeProposal(ProposalId proposalId)
        external
    {
        if (!acl.canManagePoll(address(this), proposalId, msg.sender)) revert PollACLv1.PollManagementNotAllowed();

        Proposal storage proposal = proposals[proposalId];
        if (!proposal.active) revert NotActive();

        Ballot storage ballot = _ballots[proposalId];

        uint256 topChoice;
        uint256 topChoiceCount;
        for (uint8 i; i < proposal.params.numChoices; ++i)
        {
            uint256 choiceVoteCount = ballot.voteCounts[i] & (type(uint256).max >> 1);
            if (choiceVoteCount > topChoiceCount)
            {
                topChoice = i;
                topChoiceCount = choiceVoteCount;
            }
        }

        proposals[proposalId].topChoice = uint8(topChoice);
        proposals[proposalId].active = false;
        activeProposals.remove(ProposalId.unwrap(proposalId));
        pastProposals.push(proposalId);
        emit ProposalClosed(proposalId, topChoice);
    }

    function getVoteOf(ProposalId proposalId, address voter)
        external view
        returns (Choice memory)
    {
        Proposal storage proposal = proposals[proposalId];
        Ballot storage ballot = _ballots[proposalId];

        if (voter == msg.sender) return ballot.votes[msg.sender];
        if (!proposal.params.publishVotes) revert NotPublishingVotes();
        return ballot.votes[voter];
    }

    function getVoteCounts(ProposalId proposalId)
        external view
        returns (uint256[] memory)
    {
        Proposal storage proposal = proposals[proposalId];
        Ballot storage ballot = _ballots[proposalId];

        if (proposal.active) revert StillActive();
        uint256[] memory unmaskedVoteCounts = new uint256[](MAX_CHOICES);
        for (uint256 i; i<unmaskedVoteCounts.length; i++) {
            unmaskedVoteCounts[i] = ballot.voteCounts[i] & ~(uint256(1 << 255));
        }
        return unmaskedVoteCounts;
    }

    function getVotes(ProposalId proposalId)
        external view
        returns (address[] memory, uint8[] memory) {
        Proposal storage proposal = proposals[proposalId];
        Ballot storage ballot = _ballots[proposalId];

        if (!proposal.params.publishVotes) revert NotPublishingVotes();
        if (proposal.active) revert StillActive();

        uint8[] memory choices = new uint8[](ballot.voters.length);
        for (uint256 i; i<ballot.voters.length; i++) {
            choices[i] = this.getVoteOf(proposalId, ballot.voters[i]).choice;
        }
        return (ballot.voters, choices);
    }

    function ballotIsActive(ProposalId id)
        external view
        returns (bool)
    {
        return proposals[id].active;
    }
}
