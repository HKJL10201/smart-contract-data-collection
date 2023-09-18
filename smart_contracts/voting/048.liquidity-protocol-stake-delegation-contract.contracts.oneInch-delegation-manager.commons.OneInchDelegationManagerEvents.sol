pragma solidity ^0.6.0;

import { OneInchDelegationManagerObjects } from "./OneInchDelegationManagerObjects.sol";

contract OneInchDelegationManagerEvents is OneInchDelegationManagerObjects {

    /**
     * @dev emitted when a user delegates to another
     * @param delegator the delegator
     * @param delegatee the delegatee
     * @param delegationType the type of delegation (STAKE, VOTING_POWER, DISTRIBUTION)
     */
    event DelegateChanged(
        address indexed delegator,
        address indexed delegatee,
        DelegationType delegationType
    );

    /**
     * @dev emitted when an action changes the delegated power of a user
     * @param user the user which delegated power has changed
     * @param amount the amount of delegated power for the user
     * @param delegationType the type of delegation (STAKE, VOTING_POWER, DISTRIBUTION)
     */
    event DelegatedPowerChanged(address indexed user, uint256 amount, DelegationType delegationType);

}
