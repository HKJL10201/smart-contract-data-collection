pragma solidity ^0.6.0;

contract OneInchDelegationManagerObjects {

    /**
     * @notice - delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     */
    enum DelegationType { STAKE, VOTING_POWER, REWARD_DISTRIBUTION }

    /**
     * @notice A checkpoint for marking number of votes from a given block
     */
    struct Checkpoint {
        uint128 blockNumber;  /// from block.number
        uint128 value;        /// Voting value (Voting Power) 
    }

}
