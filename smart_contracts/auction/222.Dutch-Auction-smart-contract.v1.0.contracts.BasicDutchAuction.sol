//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract BasicDutchAuction {

    address payable public seller;
    address public buyer = address(0x0);

    uint256 immutable reservePrice;
    uint256 numBlockAuctionOpen;
    uint256 immutable offerPriceDecrement;
    uint256 immutable initialPrice;

    uint256 immutable initialBlock;
    uint256 endBlock;

    constructor(uint256 _reservePrice, uint256 _numBlocksAuctionOpen, uint256 _offerPriceDecrement) {
        reservePrice = _reservePrice;
        numBlockAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        seller = payable(msg.sender);
        initialPrice = _reservePrice + (_numBlocksAuctionOpen * _offerPriceDecrement);
        initialBlock = block.number;
        endBlock = block.number + numBlockAuctionOpen;
    }

    function currentPrice() public view returns(uint256){
        return initialPrice - ((block.number - initialBlock) * offerPriceDecrement);
    }

    function bid() public payable returns(address) {
        require(buyer == address(0x0), "Auction Concluded");
        require(msg.sender != seller, "Sellers are not allowed to buy");
        require(block.number < endBlock, "Auction Closed");

        uint256 curPrice = currentPrice();
        require(msg.value >= curPrice, "Insufficient Value");

        buyer = msg.sender;

        uint256 refundAmount = msg.value - curPrice;
        if(refundAmount > 0){
            payable(msg.sender).transfer(refundAmount);
        }

        seller.transfer(msg.value - refundAmount);

        return buyer;
    }

}

