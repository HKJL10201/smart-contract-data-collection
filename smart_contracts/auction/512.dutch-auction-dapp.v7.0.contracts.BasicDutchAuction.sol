// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import 'hardhat/console.sol';

contract BasicDutchAuction {
  address payable public owner;
  uint256 public reservePrice;
  uint256 public numBlocksAuctionOpen;
  uint256 public offerPriceDecrement;

  uint256 public startBlock;
  uint256 public initialPrice;
  address public winner;

  constructor(
    uint256 _reservePrice,
    uint256 _numBlocksAuctionOpen,
    uint256 _offerPriceDecrement
  ) {
    owner = payable(msg.sender);
    reservePrice = _reservePrice;
    numBlocksAuctionOpen = _numBlocksAuctionOpen;
    offerPriceDecrement = _offerPriceDecrement;
    startBlock = block.number;

    initialPrice = reservePrice + (numBlocksAuctionOpen * offerPriceDecrement);
  }

  function getCurrentPrice() public view returns (uint256) {
    uint256 blocksElapsed = block.number - startBlock;
    console.log('Block Elasped in getCurrentPrice() :', blocksElapsed);
    if (blocksElapsed >= numBlocksAuctionOpen) {
      return reservePrice;
    } else {
      return initialPrice - (blocksElapsed * offerPriceDecrement);
    }
  }

  function bid() external payable returns (address) {
    require(winner == address(0), 'Auction has already ended.');

    uint256 blocksElapsed = block.number - startBlock;
    console.log('Block Elasped:', blocksElapsed);
    require(blocksElapsed <= numBlocksAuctionOpen, 'Auction ended.');

    uint256 currentPrice = getCurrentPrice();
    console.log('currentPrice:', currentPrice);
    console.log('msg.value:', msg.value);
    require(msg.value >= currentPrice, 'The wei value sent is not acceptable');

    winner = msg.sender;
    owner.transfer(msg.value);

    return winner;
  }
}
