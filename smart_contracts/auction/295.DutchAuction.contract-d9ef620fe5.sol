// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.3/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.3/utils/Counters.sol";

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    function safeMint(address to, uint tokenId) public  {
      _mint(to,tokenId);
    }
}


contract dutch{
    // MyToken tc;
    uint public  startPrice;
    uint public Id;
    MyToken public nft;
    uint public discountRate;
    uint public timeStart;
    uint public timeEnd;
    uint public Duration;
    address payable public auctioner;
    constructor(
        uint _startPrice,
        uint _discountRate,
        address _nft,
        uint _id
    ){
        auctioner = payable(msg.sender);
        startPrice = _startPrice;
        discountRate = _discountRate;
        require(startPrice > discountRate *10,"price is too low ");
        nft = MyToken(_nft);
        Id = _id;
        timeStart = block.timestamp;
        Duration = timeStart + 120 minutes;
        timeEnd = timeStart + Duration;

    }


       function getPrice() public view returns (uint) {
        //    require(block.number < timeEnd,"sorry auction is ended");
        uint timeElapsed = block.timestamp - timeStart;
        uint discount = discountRate + timeElapsed;
        uint finalPrice = startPrice - discount;
        return finalPrice;
    
       }

     function buy() public payable{
     require(block.timestamp < timeEnd,"sorry time is over");
     require(msg.sender != auctioner, "sorry auctioner can't buy this product");
     uint price = getPrice();
     require(msg.value >= price, "sorry price is low");
     uint refundPrice = msg.value - price;
     auctioner.transfer(price);
     nft.transferFrom(auctioner,msg.sender,Id);
     if (refundPrice > 0){
         payable(msg.sender).transfer(refundPrice);
     }
       selfdestruct(auctioner);
     }
    }