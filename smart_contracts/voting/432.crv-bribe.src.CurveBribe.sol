// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IBribeV2 {
    function add_reward_amount(address gauge, address reward_token, uint256 amount) external returns (bool);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Bribe {
    
    // BribeV2 contract address.
    address constant public BRIBE_V2 = 0x7893bbb46613d7a4FbcC31Dab4C9b823FfeE1026;

    address public incentiveToken;
    address public targetGauge;
    uint256 public amountPerVote;
    
    // Unix timestamp of the last time the incentive was paid out.
    uint256 public activePeriod;
    uint256 constant WEEK = 3600 * 24 * 7;

    // Emitted when a '_depositor' deposits '_amount' 'incentiveToken'.
    event Deposited(address indexed _depositor, uint256 _amount);
    // Emitted when 'targetGauge' is incentivized.
    event GaugeIncentivized(uint256 _date);

    constructor (address _incentiveToken, uint256 _amountPerVote, address _targetGauge) {
        incentiveToken = _incentiveToken;
        amountPerVote = _amountPerVote;
        targetGauge = _targetGauge;
    }

    // Allows anyone to deposit a desired '_amount' of 'incentiveTokens' in this contract.
    // Refunds the depositor 'refund' if 'amount' is not a multiple of 'amountPerVote'.
    // Reverts if '_amount' is less than 'amountPerVote'.
    // Depositors should first approve this contract to spend '_amount' of their 'incentiveToken'.
    function depositIncentive(uint256 _amount) external returns (bool) {
        require(_amount >= amountPerVote, "Not enough tokens");
        uint256 refund = _amount % amountPerVote;
        if (refund == 0) {
            IERC20(incentiveToken).transferFrom(msg.sender, address(this), _amount);
            emit Deposited(msg.sender, _amount);
        } else {
            uint256 deposit = _amount - refund;
            IERC20(incentiveToken).transferFrom(msg.sender, address(this), deposit);
            emit Deposited(msg.sender, deposit);
        }
        return true;
    }

    // Deposits 'amountPerVote' from this contract to the BRIBE_V2 contract.
    // Reverts if called before a week has passed since the last call,
    // meaning that the 'targetGauge' has already been incentivized by this contract for this week's vote.
    // Important : Should be called for the first time just after the weekly gauge vote goes live (Thursday 00:00 UTC)
    // so that it can only be called once per week after that, thus only allowing 1 bribe of 'amountPerVote' per vote for 'targetGauge'.
    function incentivizeGauge() external returns (bool) {
        require(block.timestamp >= activePeriod + WEEK, "Gauge already incentivized this week.");
        activePeriod = block.timestamp;
        IERC20(incentiveToken).approve(BRIBE_V2, amountPerVote);
        IBribeV2(BRIBE_V2).add_reward_amount(targetGauge, incentiveToken, amountPerVote);
        emit GaugeIncentivized(activePeriod);
        return true;
    }
}