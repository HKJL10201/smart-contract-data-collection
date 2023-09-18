// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WTIAAuction {
  using SafeMath for uint256;

  IERC20 private token;

  struct Auction {
    // block.timestamp returns uint hence dates are in uint
    uint256 startDate;
    uint256 endDate;
    uint256 startPrice;
    address creator;
    address token;
    uint256 tokenAmount;
  }

  Auction auction;

  /* _endDate would be passed through UI as the time in seconds to be directly added to
  current time an example of this would be 3600 for 1 Hour. Tokens need to be approved
  before calling createAuction(). */

  function createAuction(uint256 _endDate, uint256 _startPrice, address _token, uint256 _tokenAmount) public payable {
    token = IERC20(_token);
    auction = Auction(block.timestamp, (block.timestamp.add(_endDate)), _startPrice, msg.sender, _token, _tokenAmount);
    transfer(_tokenAmount);
  }

  function transfer(uint256 _tokenAmount) internal {
    require(token.balanceOf(msg.sender) > _tokenAmount);
    token.transferFrom(msg.sender, address(this), _tokenAmount);
  }

  // Refreshes every second
  function getPrice() public view returns (uint256) {
    uint256 startPrice = uint256(auction.startPrice);
    uint256 startDate = uint256(auction.startDate);
    uint256 timeDifference = uint256(auction.endDate.sub(startDate)); // Total time difference
    uint256 slope = uint256(startPrice.div(timeDifference)); // Cost to decrease per second
    uint256 currentTime = uint256(block.timestamp); // Current Time
    uint256 timePassed = uint256(currentTime.sub(startDate)); // Time in seconds since
    uint256 priceDecreased = uint256(slope.mul(timePassed));
    int256 price = int256(startPrice.sub(priceDecreased));
    if (price < 0){
      return 0;
    } else return uint256(price);
  }

  // Pays out the buyer instantly and send the ether to the creator
  function placeBid() public payable {
    require(msg.value >= getPrice());
    require(msg.sender != auction.creator);
    (bool success, ) = auction.creator.call{value: msg.value}("");
    require(success, "Transaction failed.");
    token.approve(address(this), token.balanceOf(address(this)));
    token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));
  }

  // Only can be called by creator and if the price is 0 meaning ended
  function expired() public {
    require(msg.sender == auction.creator);
    require(getPrice() == 0);
    token.approve(address(this), token.balanceOf(address(this)));
    // Trasnfer to auction.creator instead of msg.sender incase of an exploit
    token.transferFrom(address(this), auction.creator, token.balanceOf(address(this)));
  }
}
