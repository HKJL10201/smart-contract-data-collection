// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.0;

import { SafeMath } from '@openzeppelin/contracts/math/SafeMath.sol';

import { OneInchDelegationManagerStorages } from "./oneInch-delegation-manager/commons/OneInchDelegationManagerStorages.sol";
import { OneInchDelegationManagerEvents } from "./oneInch-delegation-manager/commons/OneInchDelegationManagerEvents.sol";
import { OneInchDelegationManagerConstants } from "./oneInch-delegation-manager/commons/OneInchDelegationManagerConstants.sol";
import { StakeDelegation } from "./StakeDelegation.sol";
import { OneInch } from "./1inch/1inch-token/OneInch.sol";


/**
 * @notice - OneInchDelegationManager contract is that assign wallet address into the StakeDelegation contract
 *         - "delegatee" is a contract address of the StakeDelegation contract
 */
contract OneInchDelegationManager is OneInchDelegationManagerStorages, OneInchDelegationManagerEvents, OneInchDelegationManagerConstants {
    using SafeMath for uint256;

    OneInch public oneInch; /// 1inch Token

    constructor(OneInch _oneInch) public {
        oneInch = _oneInch;
    }

    /**
     * @notice - Delegates all the powers to a specific user (address of delegatee)
     * @notice - Delegator must be msg.sender
     * @param delegatee - The user to which the power will be delegated
     * @param delegatedAmount - 1INCH tokens amount delegated by a user (caller)  
     */ 
    function delegate(address delegatee, uint delegatedAmount) public returns (bool) {
        /// Delegator
        address delegator = msg.sender;

        /// Transfer 1INCH tokens into a delegatee address
        oneInch.transferFrom(delegator, address(this), delegatedAmount);
        oneInch.transfer(delegatee, delegatedAmount);

        /// Register delegator address into the delegatee (the StakeDelegation contract)
        StakeDelegation stakeDelegation = StakeDelegation(delegatee);
        stakeDelegation.registerDelegator(delegator, delegatedAmount, block.number);

        /// Delegate
        _delegateByType(delegator, delegatee, DelegationType.STAKE);
        _delegateByType(delegator, delegatee, DelegationType.VOTING_POWER);
        _delegateByType(delegator, delegatee, DelegationType.REWARD_DISTRIBUTION);

        /// Save delegated-amount of delegator (for delegatee)
        delegatedAmounts[address(delegatee)][delegator] = delegatedAmount;
    }
    
    /**
     * @dev delegates the specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function _delegateByType(
        address delegator,
        address delegatee,
        DelegationType delegationType
    ) internal {
        require(delegatee != address(0), 'INVALID_DELEGATEE');

        (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

        uint256 delegatorBalance = oneInch.balanceOf(delegator);

        address previousDelegatee = _getDelegatee(delegator, delegates);

        delegates[delegator] = delegatee;

        _moveDelegatesByType(previousDelegatee, delegatee, delegatorBalance, delegationType);
        emit DelegateChanged(delegator, delegatee, delegationType);
    }

    /**
     * @dev returns the delegatee of an user
     * @param delegator the address of the delegator
     **/
    function getDelegateeByType(address delegator, DelegationType delegationType)
        external
        view
        returns (address)
    {
        (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

        return _getDelegatee(delegator, delegates);
    }

    /**
     * @dev returns the user delegatee. If a user never performed any delegation,
     * his delegated address will be 0x0. In that case we simply return the user itself
     * @param delegator the address of the user for which return the delegatee
     * @param delegates the array of delegates for a particular type of delegation
     */
    function _getDelegatee(address delegator, mapping(address => address) storage delegates)
        internal
        view
        returns (address)
    {
        address previousDelegatee = delegates[delegator];

        if (previousDelegatee == address(0)) {
          return delegator;
        }

        return previousDelegatee;
    }

    /**
     * @dev returns the delegated power of a user at a certain block
     * @param user the user
     */
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view returns (uint256) {
        (
          mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
          mapping(address => uint256) storage checkpointsCounts,

        ) = _getDelegationDataByType(delegationType);

        return _searchByBlockNumber(checkpoints, checkpointsCounts, user, blockNumber);
    }

    /**
     * @dev searches a checkpoint by block number. Uses binary search.
     * @param checkpoints the checkpoints mapping
     * @param checkpointsCounts the number of checkpoints
     * @param user the user for which the checkpoint is being searched
     * @param blockNumber the block number being searched
     **/
    function _searchByBlockNumber(
        mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
        mapping(address => uint256) storage checkpointsCounts,
        address user,
        uint256 blockNumber
    ) internal view returns (uint256) {
        require(blockNumber <= block.number, 'INVALID_BLOCK_NUMBER');

        uint256 checkpointsCount = checkpointsCounts[user];

        if (checkpointsCount == 0) {
          return oneInch.balanceOf(user);
        }

        // First check most recent balance
        if (checkpoints[user][checkpointsCount - 1].blockNumber <= blockNumber) {
          return checkpoints[user][checkpointsCount - 1].value;
        }

        // Next check implicit zero balance
        if (checkpoints[user][0].blockNumber > blockNumber) {
          return 0;
        }

        uint256 lower = 0;
        uint256 upper = checkpointsCount - 1;
        while (upper > lower) {
              uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
              Checkpoint memory checkpoint = checkpoints[user][center];
              if (checkpoint.blockNumber == blockNumber) {
                return checkpoint.value;
              } else if (checkpoint.blockNumber < blockNumber) {
                lower = center;
              } else {
                upper = center - 1;
              }
        }
        return checkpoints[user][lower].value;
    }

   /**
    * @dev moves delegated power from one user to another
    * @param from the user from which delegated power is moved
    * @param to the user that will receive the delegated power
    * @param amount the amount of delegated power to be moved
    * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
    **/
    function _moveDelegatesByType(
        address from,
        address to,
        uint256 amount,
        DelegationType delegationType
    ) internal {
        if (from == to) {
          return;
        }

        (
            mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
            mapping(address => uint256) storage checkpointsCounts,
        ) = _getDelegationDataByType(delegationType);

        if (from != address(0)) {
            uint256 previous = 0;
            uint256 fromCheckpointsCount = checkpointsCounts[from];

            if (fromCheckpointsCount != 0) {
                previous = checkpoints[from][fromCheckpointsCount - 1].value;
            } else {
                previous = oneInch.balanceOf(from);
            }

            _writeCheckpoint(
                checkpoints,
                checkpointsCounts,
                from,
                uint128(previous),
                uint128(previous.sub(amount))
            );

            emit DelegatedPowerChanged(from, previous.sub(amount), delegationType);
        }

        if (to != address(0)) {
            uint256 previous = 0;
            uint256 toCheckpointsCount = checkpointsCounts[to];
            if (toCheckpointsCount != 0) {
                previous = checkpoints[to][toCheckpointsCount - 1].value;
            } else {
                previous = oneInch.balanceOf(to);
            }

            _writeCheckpoint(
                checkpoints,
                checkpointsCounts,
                to,
                uint128(previous),
                uint128(previous.add(amount))
            );

            emit DelegatedPowerChanged(to, previous.add(amount), delegationType);
        }
    }

    /**
     * @dev Writes a checkpoint for an owner of tokens
     * @param owner The owner of the tokens
     * @param oldValue The value before the operation that is gonna be executed after the checkpoint
     * @param newValue The value after the operation
     */
    function _writeCheckpoint(
        mapping(address => mapping(uint256 => Checkpoint)) storage checkpoints,
        mapping(address => uint256) storage checkpointsCounts,
        address owner,
        uint128 oldValue,
        uint128 newValue
    ) internal {
        uint128 currentBlock = uint128(block.number);

        uint256 ownerCheckpointsCount = checkpointsCounts[owner];
        mapping(uint256 => Checkpoint) storage checkpointsOwner = checkpoints[owner];

        // Doing multiple operations in the same block
        if (
          ownerCheckpointsCount != 0 &&
          checkpointsOwner[ownerCheckpointsCount - 1].blockNumber == currentBlock
        ) {
          checkpointsOwner[ownerCheckpointsCount - 1].value = newValue;
        } else {
          checkpointsOwner[ownerCheckpointsCount] = Checkpoint(currentBlock, newValue);
          checkpointsCounts[owner] = ownerCheckpointsCount + 1;
        }
    }


    ///----------------------------------
    /// Getter methods
    ///----------------------------------

    /**
     * @notice - Get delegated-amount of a delegator (for a delegatee)
     */
    function getDelegatedAmount(address delegatee, address delegator) public view returns (uint _delegatedAmount) {
        return delegatedAmounts[address(delegatee)][delegator];
    }


    ///-------------------------------------------------------------------------------------------------------------
    /// _getDelegationDataByType() method is always here. (in order to avoid that highlight of code become "white") 
    ///-------------------------------------------------------------------------------------------------------------

    /**
     * @dev returns the delegation data (checkpoint, checkpointsCount, list of delegates) by delegation type
     * NOTE: Ideal implementation would have mapped this in a struct by delegation type. Unfortunately,
     * the AAVE token and StakeToken already include a mapping for the checkpoints, so we require contracts
     * who inherit from this to provide access to the delegation data by overriding this method.
     * @param delegationType the type of delegation
     */
    function _getDelegationDataByType(DelegationType delegationType) 
        internal 
        virtual 
        view 
        returns (
            mapping(address => mapping(uint256 => Checkpoint)) storage, /// checkpoints
            mapping(address => uint256) storage,                        /// checkpoints count
            mapping(address => address) storage                         /// delegatees list
        )
    {
        return (checkpoints, checkpointsCounts, delegates);
    }


}
