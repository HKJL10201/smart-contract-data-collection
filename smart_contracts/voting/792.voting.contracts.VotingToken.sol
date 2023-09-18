// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract VotingToken is ERC20, Ownable {
    /**
     * A new proposal has been put forward.
     *
     * @param proposal_hash hash of created proposal.
     */
    event ProposalCreated(uint256 proposal_hash);

    /**
     * Someone voted for.
     *
     * @param voter voter's address;
     * @param proposal_hash hash of the proposal that the voter voted for.
     */
    event NewVoteFor(address voter, uint256 proposal_hash);
    /**
     * Someone voted against.
     *
     * @param voter voter's address;
     * @param proposal_hash hash of the proposal that the voter voted against.
     */
    event NewVoteAgainst(address voter, uint256 proposal_hash);

    /**
     * The number of votes for and/or against the proposal has changed.
     *
     * @param proposal_hash hash of the proposal, the number of votes for
     * and/or against which has changed;
     * @param reject total power of votes against;
     * @param accept total power of votes for.
     */
    event VotesRatioChanged(
        uint256 proposal_hash,
        uint128 reject,
        uint128 accept
    );

    /**
     * Time-to-live exceeded.
     *
     * @param proposal_hash discarded proposal hash.
     */
    event ProposalDiscarded(uint proposal_hash);

    /**
     * The number of votes for exceeded 50%.
     *
     * @param proposal_hash hash of the accepted proposal.
     */
    event ProposalAccepted(uint256 proposal_hash);
    /**
     * The number of votes against exceeded 50%.
     *
     * @param proposal_hash hash of the rejected proposal.
     */
    event ProposalRejected(uint256 proposal_hash);

    /**
     * The number of simultaneously considered proposals is
     * limited by the value of {PROPOSALS_THRESHOLD}.
     */
    uint8 constant PROPOSALS_THRESHOLD = 3;

    /**
     * Represent 100% of votes.
     */
    uint128 constant TOTAL_SUPPLY = 100e6;

    /**
     *  Proposal becomes "accepted" or "rejected" completed if > 50% of votes for the same decision.
     */
    uint128 constant VOTES_THRESHOLD = TOTAL_SUPPLY / 2;

    /**
     * Time-to-live. After that time proposal becomes “discarded” if not
     * enough votes are gathered
     */
    uint256 constant TTL = 3 days;

    /**
     * Represents main data about proposal.
     */
    struct Proposal {
        /**
         * Hash of the document to vote for.
         */
        uint256 mHash;
        /**
         * The time when the proposal was created is used to calculate when the proposal is discarded.
         */
        uint256 mFromBlock;
        /**
         * Contains actual status of proposal.
         */
        Status mStatus;
        /**
         * Counters of the total number of votes "against" (the first value)
         * and "for" (the second value).
         */
        uint128[2] mSummaryVotingPower;
    }

    /**
     * Represents the voter's vote. A nil vote corresponds
     * to the abstaining vote is elected.
     */
    enum Vote {
        Nil,
        Against,
        For
    }

    /**
     * Represents the proposal's status.
     */
    enum Status {
        /**
         * Time-to-live limit reached.
         */
        Discarded,
        /**
         * Proposal accepted.
         */
        Accepted,
        /**
         * Proposal rejected.
         */
        Rejected,
        /**
         * Voting is in progress, the time limit and the required
         * number of votes "for" and "against" have not yet been riched.
         */
        Indefinite
    }

    /**
     * @dev Active proposals queue.
     */
    Proposal[PROPOSALS_THRESHOLD] mProposals;
    /**
     * @dev Voter => (Proposal's hash => Vote)
     */
    mapping(address => mapping(uint => Vote)) mVotes;

    constructor() ERC20("VotingToken", "VTK") {
        _mint(_msgSender(), TOTAL_SUPPLY);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * Provides access to view all proposals.
     *
     * @return all_proposals all proposals in queue.
     */
    function allProposals() public view returns (uint[PROPOSALS_THRESHOLD] memory all_proposals)
    {
        unchecked {
            for (uint8 i = 0; i < PROPOSALS_THRESHOLD; i++) {
                all_proposals[i] = mProposals[i].mHash;
            }
        }
    }

    /**
     * Provides access to view active proposals.
     *
     * @return active_proposals list of proposals with `Indefinite` status.
     */
    function activeProposals()
        public
        view
        returns (uint[] memory active_proposals)
    {
        uint8 size = 0;
        uint[] memory _active_proposals = new uint[](PROPOSALS_THRESHOLD);
        unchecked {
            for (uint8 i = 0; i < PROPOSALS_THRESHOLD; i++) {
                Proposal storage proposal = mProposals[i];
                if (
                    proposal.mStatus == Status.Indefinite &&
                    !_TTLExceeded(proposal)
                ) {
                    _active_proposals[size++] = proposal.mHash;
                }
            }
            active_proposals = new uint[](size);
            for (uint i = 0; i < size; i++) {
                active_proposals[i] = _active_proposals[i];
            }
        }
    }

    /**
     * Provides main information about proposal.
     *
     * @param proposal_hash proposal's hash.
     *
     * @return status proposal's status: discarded, accepted, rejected or indefinite;
     * @return total_power_against the amount of tokens voted against;
     * @return total_power_for the amount of tokens voted for.
     */
    function proposalInfo(uint proposal_hash)
        public
        view
        returns (
            Status status,
            uint128 total_power_against,
            uint128 total_power_for
        )
    {
        uint8 proposal_index = _lookupProposal(proposal_hash);
        require(proposal_index != PROPOSALS_THRESHOLD, "Unknown proposal");

        Proposal storage proposal = mProposals[proposal_index];

        total_power_against = proposal.mSummaryVotingPower[0];
        total_power_for = proposal.mSummaryVotingPower[1];

        if (proposal.mStatus != Status.Indefinite) {
            status = proposal.mStatus;
        } else if (_TTLExceeded(proposal)) {
            status = Status.Discarded;
        } else {
            status = Status.Indefinite;
        }
    }

    /**
     * Creates a new proposal if there are free slots (the limit on
     * the number of proposals considered at the same time is {PROPOSALS_THRESHOLD}).
     *
     * Emits a {ProposalCreated} event.
     *
     * Requirements:
     *
     * - `msg.sender` must have more than zero tokens.
     * - `proposal_hash` should not duplicate the active proposals in the queue.
     * - there should be free space in the proposal queue.
     *
     * @param proposal_hash hash of new proposal.
     */
    function propose(uint256 proposal_hash) public _senderHasTokens {
        // {_findFreePlace} checks that there are no duplicates.
        uint8 free = _findFreePlace(proposal_hash);
        require(
            free != PROPOSALS_THRESHOLD,
            "The limit of active proposals has been reached"
        );

        mProposals[free] = Proposal({
            mHash: proposal_hash,
            mFromBlock: block.timestamp,
            mStatus: Status.Indefinite,
            mSummaryVotingPower: [uint128(0), uint128(0)]
        });

        emit ProposalCreated(proposal_hash);
    }

    /**
     * Vote for a proposal with a hash equal to `proposal_hash`.
     *
     * Emits a {ProposalDiscarded},{NewVoteFor}, {VotesRatioChanged}
     * and {ProposalAccepted} events.
     *
     * Requirements:
     *
     * - `proposal_hash` must be in the proposal queue.
     * - voting for this proposal should be in progress.
     *
     * @param proposal_hash proposal's hash.
     */
    function acceptProposal(uint256 proposal_hash) public {
        _handleVote(Vote.For, proposal_hash);
    }

    /**
     * Vote against a proposal with a hash equal to `proposal_hash`.
     *
     * Emits a {ProposalDiscarded}, {NewVoteAgainst}, {VotesRatioChanged}
     * and {ProposalRejected} events.
     *
     * Requirements:
     *
     * - `proposal_hash` must be in the proposal queue.
     * - voting for this proposal should be in progress.
     *
     * @param proposal_hash proposal's hash.
     */
    function rejectProposal(uint256 proposal_hash) public {
        _handleVote(Vote.Against, proposal_hash);
    }

    /**
     * @dev Summarizes the processing of votes for and against a proposal.
     *
     * Emits a {NewVoteFor}, {NewVoteAgainst}, {VotesRatioChanged},
     * ProposalDiscarded, {ProposalAccepted} and {ProposalRejected} events.
     *
     * Requirements:
     *
     * - `proposal_hash` must be in the proposal queue.
     * - voting for this proposal should be in progress.
     *
     * @param vote side: 'for' of 'against';
     * @param proposal_hash proposal's hash.
     */
    function _handleVote(Vote vote, uint256 proposal_hash) private {
        uint8 proposal_index = _lookupProposal(proposal_hash);
        require(proposal_index != PROPOSALS_THRESHOLD, "Unknown proposal");

        Proposal storage proposal = mProposals[proposal_index];

        _checkTTL(proposal);
        require(proposal.mStatus == Status.Indefinite, "Voting finished");

        address voter = _msgSender();

        if (vote == Vote.For) {
            emit NewVoteFor(voter, proposal_hash);
        } else {
            // vote == Vote.Rejected (from implementation)
            emit NewVoteAgainst(voter, proposal_hash);
        }

        Vote last = mVotes[voter][proposal_hash];
        if (last == vote) {
            return;
        }

        mVotes[voter][proposal_hash] = vote;

        uint128 balance = uint128(balanceOf(voter));

        uint128[2] storage votes = proposal.mSummaryVotingPower;
        unchecked {
            votes[_voteId(vote)] += balance;
        }

        if (last != Vote.Nil) {
            votes[_voteId(last)] -= balance;
        }

        emit VotesRatioChanged(proposal_hash, votes[0], votes[1]);

        _updateStatus(proposal);
    }

    /**
     * @dev Updates the status of the proposal (`proposal.mStatus`) if more
     * than 3 days have passed since its creation, but it has not been
     * accepted or rejected.
     *
     * Emits {ProposalDiscarded}.
     *
     * @param proposal an proposal whose expiration date needs to be checked.
     */
    function _checkTTL(Proposal storage proposal)
        private
        _IsIndefinite(proposal)
    {
        unchecked {
            // An overflow cannot occur, since the `block.timestamp` is not less
            // than the time of the creation of the proposal (`proposal.mFromBlock`).
            if (_TTLExceeded(proposal)) {
                proposal.mStatus = Status.Discarded;
                emit ProposalDiscarded(proposal.mHash);
            }
        }
    }

    /**
     * @dev Checks if proposal time-to-limit exceeded.
     */
    function _TTLExceeded(Proposal storage proposal)
        private
        view
        returns (bool)
    {
        return block.timestamp - proposal.mFromBlock > TTL;
    }

    /**
     * @dev Checks whether the proposal has been accepted or rejected.
     * If yes, it updates its status and emits the corresponding event.
     *
     * Emits a {ProposalAccepted} and {ProposalRejected} events.
     *
     * @param proposal an proposal whose status needs to be checked and updated.
     */
    function _updateStatus(Proposal storage proposal)
        private
        _IsIndefinite(proposal)
    {
        uint128[2] storage votes = proposal.mSummaryVotingPower;
        if (votes[0] > VOTES_THRESHOLD) {
            proposal.mStatus = Status.Rejected;
            emit ProposalRejected(proposal.mHash);
        } else if (votes[1] > VOTES_THRESHOLD) {
            proposal.mStatus = Status.Accepted;
            emit ProposalAccepted(proposal.mHash);
        }
    }

    /**
     * @dev Translates the voice from the enum to the index in the `Proposal.mVotes` array.
     *
     * Rules:
     *
     * - {Vote.Nil} -> undefined;
     * - {Vote.Against} -> 0;
     * - {Vote.For} -> 1.
     *
     * @param vote side: 'for' or 'against'.
     *
     * @return index index of vote in `Proposal.mVotes` array.
     */
    function _voteId(Vote vote) private pure returns (uint8) {
        require(vote != Vote.Nil, "Vote.Nil has no ID");
        unchecked {
            return uint8(vote) - 1;
        }
    }

    /**
     * @dev Looking for an proposal in the queue. Returns the index
     * if the proposal was found, otherwise a special value equal to
     * the {PROPOSALS_THRESHOLD}.
     *
     * @param proposal_hash proposal's hash.
     *
     * @return index proposal's index in `mProposals` array.
     */
    function _lookupProposal(uint256 proposal_hash)
        private
        view
        returns (uint8)
    {
        unchecked {
            for (uint8 i = 0; i < PROPOSALS_THRESHOLD; i++) {
                if (mProposals[i].mHash == proposal_hash) {
                    return i;
                }
            }
            return PROPOSALS_THRESHOLD;
        }
    }

    /**
     * @dev Tries to find an empty place in the queue, and also checks that there
     * is no active voting for the new proposal.
     *
     * Algorithm: completed proposals (`Accepted` or `Rejected`) are first ousted
     * from the queue, if there are no such proposals, then the oldest discarded offer
     * is ousted; if the queue is filled with active (`Indefinite`) proposals,
     * a special value equal to the {PROPOSALS_THRESHOLD} is returned.
     *
     * Requirements:
     *
     * - `proposal_hash` should not duplicate the active proposals in the queue.
     *
     * @param proposal_hash new proposal's hash.
     *
     * @return index index of the cell in the `mProposals` array that may be occupied.
     */
    function _findFreePlace(uint256 proposal_hash) private returns (uint8) {
        uint8 finished = PROPOSALS_THRESHOLD;
        uint8 oldest_discarded = PROPOSALS_THRESHOLD;
        unchecked {
            for (uint8 i = 0; i < PROPOSALS_THRESHOLD; i++) {
                Proposal storage proposal = mProposals[i];
                _checkTTL(proposal);
                if (proposal.mStatus == Status.Indefinite) {
                    // The new proposal must not coincide with any actual (with
                    // `Indefinite` status) proposal in the queue:
                    require(
                        proposal_hash != proposal.mHash,
                        "The proposal is already in the queue."
                    );
                    continue;
                }
                if (proposal.mStatus != Status.Discarded) {
                    // Is `Accepted` or `Rejected
                    finished = i;
                    continue;
                }
                // is `Discarded`
                if (
                    oldest_discarded == PROPOSALS_THRESHOLD ||
                    proposal.mFromBlock <
                    mProposals[oldest_discarded].mFromBlock
                ) {
                    oldest_discarded = i;
                }
            }
        }
        if (finished != PROPOSALS_THRESHOLD) {
            return finished;
        }
        return oldest_discarded;
    }

    /**
     * @dev Handles a situation where the amounts of votes for and
     * against for some proposals may have changed.
     *
     * Emits a {VotesRatioChanged}, {ProposalAccepted} and {ProposalRejected} events.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        unchecked {
            for (uint8 i = 0; i < PROPOSALS_THRESHOLD; ++i) {
                Proposal storage proposal = mProposals[i];
                Vote vote_of_from = mVotes[from][proposal.mHash];
                Vote vote_of_to = mVotes[to][proposal.mHash];

                if (vote_of_from == vote_of_to) {
                    continue;
                }
                _checkTTL(proposal);
                if (proposal.mStatus != Status.Indefinite) {
                    continue;
                }

                uint128[2] storage votes = proposal.mSummaryVotingPower;
                // Overflow in the addition (+=) cannot occur, since the sum of votes
                // does not exceed the total number of tokens equal to {VOTES_THRESHOLD}
                // (the value is placed in uint128).
                //
                // Overflow in the subtraction (-=) cannot occur, since in the case of
                // a successful transfer, a value that does not exceed the balance of _one_
                // of the voters is not subtracted, which means that it does not exceed
                // the _total_ number of votes.
                if (vote_of_from == Vote.Nil) {
                    votes[_voteId(vote_of_to)] += uint128(amount);
                } else if (vote_of_to == Vote.Nil) {
                    votes[_voteId(vote_of_from)] -= uint128(amount);
                } else {
                    votes[_voteId(vote_of_from)] -= uint128(amount);
                    votes[_voteId(vote_of_to)] += uint128(amount);
                }

                emit VotesRatioChanged(proposal.mHash, votes[0], votes[1]);
                _updateStatus(proposal);
            }
        }
    }

    /**
     * Requirements:
     *
     * - `msg.sender` has more then zero token.
     */
    modifier _senderHasTokens() {
        require(
            balanceOf(_msgSender()) >= 0,
            "The operation is allowed only for senders who have voting tokens."
        );
        _;
    }

    /**
     * Performs the operation only if the offer is active.
     */
    modifier _IsIndefinite(Proposal storage proposal) {
        if (proposal.mStatus == Status.Indefinite) {
            _;
        }
    }
}
