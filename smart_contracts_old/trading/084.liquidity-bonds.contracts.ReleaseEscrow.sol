// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Openzeppelin
import "./openzeppelin-solidity/contracts/ERC20/SafeERC20.sol";
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ReentrancyGuard.sol";

// Interfaces
import "./interfaces/IReleaseSchedule.sol";
import "./interfaces/IBackupMode.sol";

// Inheritance
import "./interfaces/IReleaseEscrow.sol";

/**
 * Escrow to release tokens according to a schedule.
 */
contract ReleaseEscrow is ReentrancyGuard, IReleaseEscrow {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // When the release starts.
    uint256 public immutable override startTime;

    // Reward token contract address.
    IERC20 public immutable rewardToken;

    // LiquidityBond contract.
    address public immutable beneficiary;

    // StakingRewards contract.
    address public immutable backupBeneficiary;

    // Schedule for release of tokens.
    IReleaseSchedule public immutable schedule;

    // Keep track of whether the protocol is in backup mode.
    // Rewards go to StakingRewards contract during backup mode.
    IBackupMode public backupMode;

    // Timestamp of the last withdrawal.
    uint256 public lastWithdrawalTime;

    // Total number of tokens that will be distributed.
    uint256 public override lifetimeRewards;

    // Number of tokens that have been claimed.
    uint256 public override distributedRewards;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _liquidityBond, address _stakingRewards, address _rewardToken, address _schedule, address _backupMode) {
        beneficiary = _liquidityBond;
        backupBeneficiary = _stakingRewards;
        rewardToken = IERC20(_rewardToken);
        schedule = IReleaseSchedule(_schedule);
        backupMode = IBackupMode(_backupMode);
        startTime = IReleaseSchedule(_schedule).distributionStartTime();
        lastWithdrawalTime = IReleaseSchedule(_schedule).getStartOfCurrentCycle();
        lifetimeRewards = IReleaseSchedule(_schedule).getTokensForCycle(1).mul(2);
    }

    /* ========== VIEWS ========== */

    /**
     * Returns true if release has already started.
     */
    function hasStarted() public view override returns (bool) {
        return block.timestamp >= startTime;
    }

    /**
     * Returns the number of tokens left to distribute.
     */
    function remainingRewards() external view override returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    /**
     * Returns the number of tokens that have vested based on a schedule.
     */
    function releasedRewards() public view override returns (uint256) {
        return lifetimeRewards.sub(rewardToken.balanceOf(address(this)));
    }

    /**
     * Returns the number of vested tokens that have not been claimed yet.
     */
    function unclaimedRewards() external view override returns (uint256) {
        return releasedRewards().sub(distributedRewards);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

   /**
     * Withdraws tokens based on the current reward rate and the time since last withdrawal.
     * @notice This function is called by the LiquidityBond contract whenever a user claims rewards.
     * @return uint256 Number of tokens claimed.
     */
    function withdraw() external override started onlyBeneficiary nonReentrant returns(uint256) {
        uint256 startOfCycle = schedule.getStartOfCurrentCycle();
        uint256 availableTokens = 0;

        // Check for cross-cycle rewards
        if (lastWithdrawalTime < startOfCycle) {
            availableTokens = (startOfCycle.sub(lastWithdrawalTime)).mul(schedule.getCurrentRewardRate().mul(2));
            availableTokens = availableTokens.add((block.timestamp.sub(startOfCycle)).mul(schedule.getCurrentRewardRate()));
        }
        else {
            availableTokens = (block.timestamp.sub(lastWithdrawalTime)).mul(schedule.getCurrentRewardRate());
        }
        
        lastWithdrawalTime = block.timestamp;
        distributedRewards = distributedRewards.add(availableTokens);
        rewardToken.safeTransfer(backupMode.useBackup() ? backupBeneficiary : beneficiary, availableTokens);

        return availableTokens;
    }

    /* ========== MODIFIERS ========== */

    modifier started {
        require(hasStarted(), "ReleaseEscrow: release has not started yet");
        _;
    }

    modifier onlyBeneficiary {
        require((msg.sender == beneficiary && !backupMode.useBackup()) ||
                (msg.sender == backupBeneficiary && backupMode.useBackup()),
                "ReleaseEscrow: only the beneficiary can call this function");
        _;
    }
}