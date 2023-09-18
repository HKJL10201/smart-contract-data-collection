//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

//In Dutch Auction, price goes down as time passes
//We can buy a certain item, when price becomes low enough
//This exercise will make an auction for an NFT which is a ERC721 token.

contract DutchAuction {
    uint private constant DURATION = 7 days; //Auction is 7 days

    // The variables below will NOT change during the duration of the auction.
    // Which means they can be immutable. After we finish Auction, we will deploy
    // a new contract and there we can make redefine these variables.
    IERC721 public immutable nft; 
    uint public immutable nftId;

    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable expiresAt;
    uint public immutable discountRate; //daily discount rate
    
    constructor (uint _startinPrice, uint _discountRate, address _nft, uint _nftId) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        startAt = block.timestamp; // The auction starts when the contract is deployed
        expiresAt = block.timestamp + DURATION;

        //Immutable state variables cannot be accessed from inside the constructor. Thats why
        // we say "_startingPrice" not startingPrice.
        //We are making sure the startingPrice is bigger than 0
        require(_startingPrice >= _discountRate*DURATION, "starting price < 0"); 

        discountRate = _discountRate;
        nft = IERC721(_nft);
        nftId = _nftId;
    }

    function getPrice() public view returns(uint) {
        uint timeElapsed = block.timestamp - startAt;
        uint discount = discountRate * timeElapsed; 
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < expiresAt, "auction ended");
        uint price = getPrice();
        require(msg.value >= price, "ETH < price");
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if(refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        selfdestruct(seller); 
    }
}