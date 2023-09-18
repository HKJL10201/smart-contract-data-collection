// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/**
 * The core contract that contains all the logic and primitives. It is abstract
 * and requires choosing some of the modules below, or custom ones
 */
import '@openzeppelin/contracts/governance/Governor.sol';

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 */
abstract contract GovernorSettings is Governor {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _minimumVotingPeriod;
    uint256 private _proposalThreshold;

    event LogVotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event LogVotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event LogMinimumVotingPeriodSet(
        uint256 oldMinimumVotingPeriod,
        uint256 newMinimumVotingPeriod
    );
    event LogProposalThresholdSet(
        uint256 oldProposalThreshold,
        uint256 newProposalThreshold
    );

    /// @dev Initialize the governance parameters.
    constructor(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialMinimumVotingPeriod,
        uint256 initialProposalThreshold
    ) {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setMinimumVotingPeriod(initialMinimumVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /// @dev See {IGovernor-votingDelay}.
    function votingDelay() public view override returns (uint256) {
        return _votingDelay;
    }

    /// @dev See {IGovernor-votingPeriod}.
    function votingPeriod() public view override returns (uint256) {
        return _votingPeriod;
    }

    /// @dev Minimum delay, in number of blocks, between the vote start and vote
    /// ends.
    function minimumVotingPeriod() public view returns (uint256) {
        return _minimumVotingPeriod;
    }

    /// @dev See {Governor-proposalThreshold}.
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed
     * through a governance proposal.
     *
     * Emits a {LogVotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed
     * through a governance proposal.
     *
     * Emits a {LogVotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the minimum voting period. This operation can only be
     * performed through a governance proposal.
     *
     * Emits a {LogMinimumVotingPeriodSet} event.
     */
    function setMinimumVotingPeriod(uint256 newMinimumVotingPeriod)
        public
        onlyGovernance
    {
        _setMinimumVotingPeriod(newMinimumVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed
     * through a governance proposal.
     *
     * Emits a {LogProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold)
        public
        onlyGovernance
    {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {LogVotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal {
        emit LogVotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {LogVotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, 'Voting period too low');
        emit LogVotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the minimum voting period.
     *
     * Emits a {LogMinimumVotingPeriodSet} event.
     */
    function _setMinimumVotingPeriod(uint256 newMinimumVotingPeriod) internal {
        // Voting period must be at least one block long
        require(newMinimumVotingPeriod > 0, 'Minimum voting period too low');
        emit LogMinimumVotingPeriodSet(
            _minimumVotingPeriod,
            newMinimumVotingPeriod
        );
        _minimumVotingPeriod = newMinimumVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {LogProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal {
        emit LogProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }
}
