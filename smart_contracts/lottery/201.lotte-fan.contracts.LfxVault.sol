// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// We import this library to be able to use console.log
import 'hardhat/console.sol';

contract LfxVault {
  IERC20 public immutable token;
  uint private aDayInSeconds = 86400;

  uint public totalSupply;
  uint public initTimestamp;

  mapping(address => uint) public balanceOf;
  mapping(address => uint) public avgDepositTs; // average deposit timestamp

  constructor(address _token) {
    token = IERC20(_token);
    initTimestamp = block.timestamp;
  }

  function _mint(address _to, uint _amount) private {
    totalSupply += _amount;
    balanceOf[_to] += _amount;
  }

  function _burn(address _from, uint _amount) private {
    totalSupply -= _amount;
    balanceOf[_from] -= _amount;
  }

  function _getTotalDays(uint totalSecond) private view returns (uint) {
    return totalSecond / aDayInSeconds;
  }

  function _getTotalInterest(address sender) private view returns (uint) {
    if (
      block.timestamp < aDayInSeconds + initTimestamp + avgDepositTs[sender]
    ) {
      return 0;
    }

    uint vaultBalance = token.balanceOf(address(this));
    uint totalDay = _getTotalDays(block.timestamp - initTimestamp);

    // calculate the yield per day per token
    // 1e6 is used to avoid floating point
    uint yieldPerTokenPerDay = (totalSupply != 0 && totalDay != 0)
      ? ((vaultBalance - totalSupply) * 1e6) / totalSupply / totalDay
      : 0;

    // calculate the interest based on the average deposit timestamp
    // reduce 1e6 from previous calculation
    uint interest = (((balanceOf[sender] * yieldPerTokenPerDay) / 1e6) *
      _getTotalDays(block.timestamp - initTimestamp - avgDepositTs[sender]));

    return interest;
  }

  function deposit(uint _amount) external {
    // every second, the vault will get a portion of the yield
    uint tsVaultBlock = block.timestamp - initTimestamp;

    if (avgDepositTs[msg.sender] == 0) {
      avgDepositTs[msg.sender] = tsVaultBlock;
    } else {
      uint totalDeposit = balanceOf[msg.sender] + _amount;
      uint avgTs = (balanceOf[msg.sender] *
        avgDepositTs[msg.sender] +
        _amount *
        tsVaultBlock) / totalDeposit;
      avgDepositTs[msg.sender] = avgTs;
    }

    _mint(msg.sender, _amount);
    token.transferFrom(msg.sender, address(this), _amount);
  }

  function withdraw(uint _amount) external {
    require(_amount <= balanceOf[msg.sender], 'LfxVault: insufficient balance');

    uint vaultBalance = token.balanceOf(address(this));
    uint totalDay = _getTotalDays(block.timestamp - initTimestamp);

    // calculate the yield per day per token
    // 1e6 is used to avoid floating point
    uint yieldPerTokenPerDay = (totalSupply != 0 && totalDay != 0)
      ? ((vaultBalance - totalSupply) * 1e6) / totalSupply / totalDay
      : 0;

    // calculate the interest based on the average deposit timestamp
    // reduce 1e6 from previous calculation
    uint interest = (((_amount * yieldPerTokenPerDay) / 1e6) *
      _getTotalDays(
        block.timestamp - initTimestamp - avgDepositTs[msg.sender]
      ));

    // user will withdraw the amount plus the interest
    // there is no need to check if the vault has enough balance
    // since the interest is calculated based on the vault balance
    uint amountToWithdraw = _amount + interest;

    _burn(msg.sender, _amount);
    token.transfer(msg.sender, amountToWithdraw);
  }

  function getTotalInterest(address sender) public view returns (uint) {
    return _getTotalInterest(sender);
  }

  function withdrawAllInterest() external {
    uint interest = _getTotalInterest(msg.sender);
    require(interest > 0, 'LfxVault: no interest to withdraw');

    avgDepositTs[msg.sender] = block.timestamp;
    token.transfer(msg.sender, interest);
  }

  function getInformation() external view returns (uint, uint, uint) {
    uint vaultBalance = token.balanceOf(address(this));
    uint totalDay = _getTotalDays(block.timestamp - initTimestamp);

    // calculate the yield per day per token
    uint yieldPerTokenPerDay = (totalSupply != 0 && totalDay != 0)
      ? ((vaultBalance - totalSupply) * 1e6) / totalSupply / totalDay
      : 0;

    return (totalSupply, vaultBalance, yieldPerTokenPerDay);
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint amount);
  event Approval(address indexed owner, address indexed spender, uint amount);
}
