//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721{
    function transferFrom(
        address _from,
        address _to,
        uint _nftId
    )
    external ;
}

contract DutchAuction{
    uint private constant DURATION = 1 days;
    IERC721 public immutable nft;
    uint public immutable nftId;
    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable expiresAt;
    uint public immutable discountRate;

    constructor(
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId) {
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        require(_startingPrice >= _discountRate * DURATION, "Starting price is too low");}

    function getPrice() public view returns(uint price){
        uint timeElasped = block.timestamp + startAt;
        uint discount = discountRate * timeElasped;
        price = startingPrice - discount;
    }
    function buy() external payable{
        require(block.timestamp < expiresAt, "auction has expired");
        uint price = getPrice();
        require(msg.value >= price, "Insufficient funds");
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if (refund > 0){
            payable(msg.sender).transfer(refund);
             selfdestruct(seller); }
    }
   
}
