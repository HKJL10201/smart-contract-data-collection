// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './AwesomeTokens.sol';
import './LotteryChainlink.sol';

contract Presale is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  AwesomeTokens public tokens;
  Lottery public lottery;
  mapping(address => bool) public withdrawn;
  uint256 costPrice;
  uint256 reward;
  bool public presaleEnd;

  constructor() {
    costPrice = 0.01 ether;
    reward = 1000 ether;
    tokens = new AwesomeTokens(1000000 ether);
    tokens.whitelist(msg.sender);
    tokens.transferOwnership(msg.sender);
    lottery = new Lottery();
    lottery.transferOwnership(msg.sender);
  }

  function withdraw() external payable nonReentrant {
    require(
      lottery.isWinner(msg.sender) == true && withdrawn[msg.sender] == false,
      'Winners can only withdraw once'
    );
    require(msg.value >= costPrice, 'please pay 0.01 ether');

    withdrawn[msg.sender] = true;
    uint256 refund = (msg.value).sub(costPrice);
    uint256 tokensToTransfer = reward;

    (bool refundSuccess, ) = msg.sender.call{ value: refund }('');
    require(refundSuccess, 'Failed to send Ether');
    tokens.transfer(msg.sender, tokensToTransfer);
  }

  function isWinner(address _address) external view returns (bool) {
    return lottery.isWinner(_address);
  }

  function ownerWithdraw() external payable onlyOwner {
    require(
      address(this).balance == 10 ether &&
        tokens.balanceOf(address(this)) == 0 ether,
      'Presale has not ended yet'
    );
    presaleEnd = true;
    (bool txSuccess, ) = msg.sender.call{ value: address(this).balance }('');
    require(txSuccess, 'transaction failed');
  }
}
