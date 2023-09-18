pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a parameter or an account)
 * stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {
  event Deposited(address indexed account, uint256 totalDeposit);

  event Withdrawn(
    address indexed account,
    address withdrawnAddress,
    uint256 amount
  );

  // emitted when stake or unstake delay are modified
  event StakeLocked(
    address indexed account,
    uint256 totalStaked,
    uint256 unstakeRelaySec
  );

  // emitted once a stake is schedule for withdrawal
  event StakeUnlocked(address indexed account, uint256 withdrawTime);

  event StakeWithdrawn(
    address indexed account,
    address withdrawnAddress,
    uint256 amount
  );

  /**
   * @param deposit the entity's deposit
   * @param staked true if this entity is staked
   * @param unstakedDelaySec minimum delay to withdraw the stake.
   * @param withdrawTime first block timestamp where 'withdrawStake' will be callable, or zero if already locked
   * @dev size were chosen so that it fit into 1 cell and the rest fit into a 2nd cell
   */
  struct DepositInfo {
    uint112 deposit;
    bool staked;
    uint112 stake;
    uint32 unstakeDelaySec;
    uint48 withdrawTime;
  }

  // api struct used by getStakeInfo and simulateValidation
  struct StakeInfo {
    uint256 stake;
    uint256 unstakeDelaySec;
  }

  /// @return info - full deposit information of given account
  function getDepositInfo(
    address account
  ) external view returns (DepositInfo memory info);

  // @return the deposit (for gas payment) of the account
  function balanceOf(address account) external view returns (uint256);

  // add deposit of to the given account
  function depositTo(address account) external payable;

  /**
   * add to the account's stake - amount and delay
   * any pending unstake is first cancelled.
   * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn
   */
  function addStake(uint32 _unstakeDelaySec) external payable;

  /**
   * attempt to unlock the stake.
   * the value can be withdrawn (using withdrawStake) after the unstake delay.
   */
  function unlockStake() external;

  /**
   * withdraw from the (unlocked) stake
   * must first call unlockStake and wait for the unstakeDelay to pass.
   * @param withdrawAddress the address to sen withdrawn value.
   */
  function withdrawStake(address payable withdrawAddress) external;

  /**
   * withdraw from the deposit
   * @param withdrawAddress the address to send withdrawn value.
   * @param withdrawAmount the amount to withdraw.
   */
  function withdrawTo(
    address payable withdrawAddress,
    uint256 withdrawAmount
  ) external;
}
