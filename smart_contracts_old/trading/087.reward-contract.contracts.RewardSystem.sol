//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "./ERC20Token.sol";

contract RewardSystem {
  using SafeMath for uint256;
  ERC20Token public erc20Token;

  uint256 public rewardRate = 387;
  uint256 private startTradingAt;
  uint256 public uintPeriod = 2592000;

  mapping (uint256 => mapping (address => uint256)) ownedTradingVolume;
  uint256 public marketValue;
  mapping (address => uint256) public ownedReward;
  uint256[] periods;
  address[] accounts;

  constructor(address _tokenAddress) {
    startTradingAt = block.timestamp;
    erc20Token = ERC20Token(_tokenAddress);
  }

  function setERC20Token(address _tokenAddress) public {
    erc20Token = ERC20Token(_tokenAddress);
  }

  function calcuReward(
    uint256 period,
    uint256 tradingValue, 
    uint256 totalValue)
    private view returns (uint256) {
      uint256 resultPerPeriod = rewardRate.mul(period).mul(tradingValue).div(totalValue).div(1000);
      return resultPerPeriod;
  }

  function trading(address account, uint256 amount) public {
    erc20Token.transferFrom(msg.sender, address(this), amount);
    if(periods.length > 2) {
      uint256 beforeTime = periods[(periods.length).sub(1)];
      for(uint j = 0; j < accounts.length; j++){
        uint256 tradingValue = ownedTradingVolume[beforeTime][accounts[j]] ; 
        ownedReward[accounts[j]] = ownedReward[accounts[j]].add(calcuReward(block.timestamp.sub(beforeTime), tradingValue, marketValue));
      }
      if(block.timestamp > startTradingAt.add(uintPeriod)){ 
        startTradingAt = startTradingAt.add(uintPeriod);
        marketValue = 0;
        for(uint i = 0; i < periods.length; i++){
          for(uint j = 0; j < accounts.length; j++){
            delete ownedTradingVolume[periods[i]][accounts[j]];
          }
        }
        delete accounts;
        accounts.push(account);
      }
    }
    periods.push(block.timestamp);
    if(!uniqAddress(account)){
      accounts.push(account);
    }
    ownedTradingVolume[block.timestamp][account] = ownedTradingVolume[block.timestamp][account].add(amount);
    marketValue = marketValue.add(amount);
  }
  
  function withdraw(address payable account) public returns(bool) {
    erc20Token.transferFrom(address(this), account, ownedReward[account]);
    return true;
  }

  function uniqAddress(address account) public view returns(bool) {
    for(uint j = 0; j < accounts.length; j++){
      if(accounts[j] != account){
        return false;
      }
    }
    return true;
  }
}
