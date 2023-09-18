//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AucEngine is Ownable {
    uint constant DURATION = 2 days;
    uint constant FEE = 10; // 10%
    uint private availableFee;

    struct Auction {
        address payable seller;
        uint startingPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctions;

    event auctionCreated(uint index, string itemName, uint startingPrice, uint duration);
    event auctionEnded(uint index, uint finalPrice, address winner);

    function createAuction(
        uint _strartingPrice,
        uint _discountRate,
        string calldata _item,
        uint _duration
    ) external
    {
        require(_strartingPrice >= _discountRate * _duration, "incorrect starting price");

        _duration = _duration == 0 ? DURATION : _duration;

        Auction memory newAuciton = Auction({
            seller: payable(msg.sender),
            startingPrice: _strartingPrice,
            finalPrice:  _strartingPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endsAt: block.timestamp + _duration,
            item : _item,
            stopped: false
        });

        auctions.push(newAuciton);

        emit auctionCreated(auctions.length - 1, _item, _strartingPrice, _duration);
    }

    function getPriceFor(uint index) public view returns(uint) {
        Auction memory auction = auctions[index];
        uint elapsed = block.timestamp - auction.startAt;
        uint discount = auction.discountRate * elapsed;
        return auction.startingPrice - discount;
    }

    function buy(uint index) external payable {
        Auction storage auction = auctions[index];

        require(!auction.stopped, "stopped!");
        require(block.timestamp < auction.endsAt, "ended!");

        uint price = getPriceFor(index);
        require(msg.value >= price, "Not enough funds!");

        auction.stopped = true;
        auction.finalPrice = price;

        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        auction.seller.transfer(
            price - ((price * FEE) / 100)
        );
        availableFee += price / FEE;
        emit auctionEnded(index, price, msg.sender);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(availableFee);
        availableFee = 0;
    }
}
