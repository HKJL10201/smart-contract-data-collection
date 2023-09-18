// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.4.2/contracts/access/Ownable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.4.2/contracts/token/ERC20/utils/SafeERC20.sol";

contract DutchAuction is Ownable {
    address payable public immutable seller;
    IERC20 public immutable token;

    address payable public buyer;

    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public startPrice;
    uint256 public reservationPrice;

    uint256 public duration;
    uint256 public priceRange;

    constructor(IERC20 _token) {
        seller = payable(msg.sender);
        token  = _token;
    }
    
    receive() payable external {
        revert('This contract cannot store ETH');
    }
    

    // State Functions
    function isAuctionReady() public view returns (bool) {
        return startTimestamp != 0;
    }

    function hasAuctionStarted() public view returns (bool) {
        return startTimestamp != 0 && block.timestamp >= startTimestamp;
    }

    function hasAuctionFinished() public view returns (bool) {
        return startTimestamp != 0 && block.timestamp >= endTimestamp;
    }

    function isAuctionOngoing() public view returns (bool) {
        return startTimestamp != 0 && block.timestamp >= startTimestamp && block.timestamp < endTimestamp;
    }

    function isAuctionDeserted() public view returns (bool) {
        require(startTimestamp != 0, 'The auction has not been launched');
        require(block.timestamp >= endTimestamp || buyer != address(0), 'The auction has not finished.');

        return buyer == address(0);
    }   


    // Auction Functions
    function launchAuction(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _startPrice,
        uint256 _reservationPrice
    ) external onlyOwner {
        require(startTimestamp == 0, 'The auction has already been launched');
        require(token.balanceOf(address(this)) > 0, 'There are no tokens to auction');
        require(_startTimestamp > block.timestamp, 'The start date has to be after the current date.');
        require(_startTimestamp < _endTimestamp, 'The start date cannot be after the end date');
        require(_startPrice > 0, 'The start price must be non-zero.');
        require(_reservationPrice < _startPrice, 'The reservation price must be smaller than the start price.');

        startTimestamp   = _startTimestamp;
        endTimestamp     = _endTimestamp;
        startPrice       = _startPrice;
        reservationPrice = _reservationPrice;

        duration         = _endTimestamp - _startTimestamp;
        priceRange       = _startPrice - _reservationPrice;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 nowTimestamp = block.timestamp;

        // Check that the auction is ongoing
        require(nowTimestamp >= startTimestamp, 'Auction has not started.');
        require(nowTimestamp < endTimestamp && buyer == address(0), 'Auction has finished');

        uint256 currentPrice = startPrice - (priceRange * (nowTimestamp - startTimestamp)) / duration;
        require(currentPrice > reservationPrice, 'Auction has finished');
        // The currentPrice is checked to be larger than the reservationPrice to take care of possible rounding errors

        return currentPrice;
    }

    function buy() external payable returns (uint256) {
        uint256 price = getCurrentPrice(); // Note that this call checks if the auction is ongoing

        require(msg.sender != seller, 'The buyer cannot be the seller');
        require(msg.value >= price, 'Not enough funds to buy at the current price');

        buyer = payable(msg.sender);

        // Send auction price to seller
        seller.transfer(price);

        // Send tokens to buyer
        token.transfer(buyer, getTokenBalance());
        
        // Return excess funds to buyer        
        uint256 refund = msg.value - price;
        if (refund > 0) buyer.transfer(refund);

        return price;
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function retrieveTokens() external onlyOwner {
        // Tokens can only be recovered by the owner before the auction is launched and after the auction has completed
        require(
            startTimestamp == 0 || 
            block.timestamp >= endTimestamp ||
            buyer != address(0)
            , 'Tokens cannot be recovered once the auction has been launched and it hasn\'t finished.'
        );

        token.transfer(seller, getTokenBalance());
    }

    function retrieveFunds() external payable onlyOwner {
        // Precaution: always allow the seller to recover the ETH funds of the contract
        seller.transfer(address(this).balance);
    }

}