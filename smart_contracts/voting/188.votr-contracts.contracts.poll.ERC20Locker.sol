// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol';
import '../interfaces/IVotrPoll.sol';

abstract contract ERC20Locker is ERC20Wrapper {
  uint32 internal constant SECONDS_IN_YEAR = 31556926;
  uint32 internal constant INCREASE_OF_VOTING_POWER_PER_SECOND = 105629215; // / 10**16;
  uint8 internal constant MAX_BONUS_MULTIPLIER = 2;

  event Deposited(address indexed depositor, uint256 amountDeposited, uint256 startDate, uint256 endDate);

  struct Deposit {
    uint256 amountDeposited;
    uint256 startDate;
    uint256 endDate;
  }
  mapping(address => Deposit) public userDeposits;
  mapping(address => bool) public hasLocked;
  address public pollType;
  address public votrPollContract;

  constructor(
    IERC20 underlyingToken,
    address _pollType,
    address _votrPollContract
  ) ERC20Wrapper(underlyingToken) {
    pollType = _pollType;
    votrPollContract = _votrPollContract;
  }

  function lock(uint256 amount, uint256 endDate) public returns (uint256 depositId) {
    require(amount > 0, 'Cannot lock 0 tokens');
    require(hasLocked[msg.sender] == false, 'Already deposited funds');

    depositFor(msg.sender, amount);
    hasLocked[msg.sender] = true;
    Deposit memory deposit = Deposit({ amountDeposited: amount, startDate: block.timestamp, endDate: endDate });

    emit Deposited(msg.sender, deposit.amountDeposited, deposit.startDate, endDate);
    uint256 bonus = _calculateBonusForLockupPeriod(deposit);

    require(endDate > block.timestamp || endDate == 0, 'Lockup period cannot end in past');

    if (endDate != 0) {
      _mint(msg.sender, _calculateBonusForLockupPeriod(deposit));
    }

    userDeposits[msg.sender] = deposit;
    _approve(msg.sender, pollType, amount + bonus);
    return depositId;
  }

  function _calculateBonusForLockupPeriod(Deposit memory deposit) internal pure returns (uint256 bonus) {
    if (deposit.endDate == 0) return 0;
    // no need for safe math, since solidity 0.8.0 reverts transaction on underflow
    uint256 lockupPeriod = deposit.endDate - deposit.startDate;
    uint256 maxBonusLockupPeriod = SECONDS_IN_YEAR * 3;
    lockupPeriod = lockupPeriod > maxBonusLockupPeriod ? maxBonusLockupPeriod : lockupPeriod;

    uint256 multiplier = (INCREASE_OF_VOTING_POWER_PER_SECOND * lockupPeriod) * MAX_BONUS_MULTIPLIER;
    return (deposit.amountDeposited * multiplier) / 10**16;
  }

  function unlock() public {
    Deposit memory deposit = userDeposits[msg.sender];
    require(deposit.amountDeposited != 0, 'There is no deposit');
    require(deposit.endDate < block.timestamp, 'Locking period not finished');

    uint256 amountOfTokensToBurn = min(balanceOf(msg.sender), deposit.amountDeposited);
    _burn(msg.sender, amountOfTokensToBurn);
    IERC20(underlying).transfer(msg.sender, deposit.amountDeposited);
    unchecked {
      _approve(msg.sender, pollType, allowance(msg.sender, pollType) - deposit.amountDeposited);
    }

    delete userDeposits[msg.sender];
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }
}
