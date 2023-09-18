// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC20.sol";

contract StakingRewards is AccessControl {
    /* ======================= Setters ======================= */

    ERC20 private rewardsToken;
    IERC20 private stakingToken;

    uint256 public rewardRate;
    uint256 public minStakingTime;
    uint256 public rewardStartTime;

    struct Stakeholder {
        uint256 stake;
        uint256 lastStakeTime;
        uint256 rewardsAvailable;
    }

    mapping(address => Stakeholder) public stakeholders;

    /* ======================= Constructor ======================= */

    constructor(address _stakingToken, address _rewardsToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingToken = IERC20(_stakingToken);
        rewardsToken = ERC20(_rewardsToken);
        rewardRate = 20;
        minStakingTime = 10;
        rewardStartTime = 20;
    }

    /* ======================= Modifiers ======================= */

    modifier checkStakingTime() {
        require(
            stakeholders[msg.sender].lastStakeTime +
                minStakingTime *
                1 minutes <
                block.timestamp,
            "Stake is still freezed"
        );
        _;
    }

    modifier updateReward(address stakeholder) {
        require(
            stakeholders[stakeholder].lastStakeTime +
                rewardStartTime *
                1 minutes <
                block.timestamp,
            "Rewards are not available yet"
        );
        stakeholders[stakeholder].rewardsAvailable = _calculateReward(
            msg.sender
        );
        _approveRewards(
            stakeholder,
            stakeholders[stakeholder].rewardsAvailable
        );
        _;
    }

    /* ======================= Functions ======================= */

    function getStakeholderStake(address stakeholder)
        external
        view
        returns (uint256)
    {
        return stakeholders[stakeholder].stake;
    }

    function getStakeholderRewards(address stakeholder)
        external
        view
        returns (uint256)
    {
        return stakeholders[stakeholder].rewardsAvailable;
    }

    function _approveRewards(address stakeholder, uint256 amount) internal {
        rewardsToken.increaseAllowance(stakeholder, amount);
    }

    function _disapproveRewards(address stakeholder, uint256 amount) internal {
        rewardsToken.decreaseAllowance(stakeholder, amount);
    }

    function _calculateReward(address shareholder) internal returns (uint256) {
        uint256 coefficient = (block.timestamp -
            stakeholders[shareholder].lastStakeTime) /
            (rewardStartTime * 1 minutes);

        for (uint256 i = 0; i < coefficient; i++) {
            stakeholders[shareholder].rewardsAvailable +=
                (stakeholders[shareholder].stake * rewardRate * 100) /
                10000;
        }

        return stakeholders[shareholder].rewardsAvailable;
    }

    function _transferStake(address stakeholder, uint256 amount) internal {
        stakingToken.transfer(stakeholder, amount);
    }

    function stake(uint256 amount) external returns (bool) {
        require(
            stakingToken.balanceOf(msg.sender) >= amount,
            "Not have anough funds"
        );

        stakeholders[msg.sender].stake += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakeholders[msg.sender].lastStakeTime = block.timestamp;

        emit Staked(msg.sender, amount);
        return true;
    }

    function claim() external updateReward(msg.sender) returns (bool) {
        uint256 reward = stakeholders[msg.sender].rewardsAvailable;
        rewardsToken.transfer(msg.sender, reward);
        stakeholders[msg.sender].rewardsAvailable = 0;
        _disapproveRewards(msg.sender, reward);

        return true;
    }

    function unstake(uint256 amount) external checkStakingTime returns (bool) {
        require(
            stakeholders[msg.sender].stake >= amount,
            "Claimed amount exceeds the stake"
        );
        _transferStake(msg.sender, amount);
        stakeholders[msg.sender].stake -= amount;
        emit Unstaked(msg.sender, amount);

        return true;
    }

    /* ======================= Restricted functions ======================= */

    function changeRewardRate(uint256 newRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        rewardRate = newRate;
        return true;
    }

    function changeMinStakingTime(uint256 newMinStakingTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        minStakingTime = newMinStakingTime;
        return true;
    }

    function changeRewardStartTime(uint256 newRewardStartTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        rewardStartTime = newRewardStartTime;
        return true;
    }

    /* ======================= Events ======================= */

    event Staked(address indexed stakeholder, uint256 amount);
    event Unstaked(address indexed stakeholder, uint256 amount);
}
