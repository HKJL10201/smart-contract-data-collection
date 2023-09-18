//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface MintNFTokens{
     function safeTransferFrom(address from, address to, uint256 tokenId) external;
     function ownerOf(uint256 tokenId) external view returns(address owner);
}

contract NFTDutchAuction {

    address payable public seller;
    address public currentOwner;
    address public buyer = address(0x0);

    uint256 immutable reservePrice;
    uint256 numBlockAuctionOpen;
    uint256 immutable offerPriceDecrement;
    uint256 immutable initialPrice;
    
    uint256 immutable initialBlock;
    uint256 endBlock;

    uint256 immutable nfTokenId;
    address immutable tokenAddress;
    MintNFTokens mint;

    constructor(address _tokenAddress, uint256 _nfTokenId, uint256 _reservePrice, uint256 _numBlocksAuctionOpen, uint256 _offerPriceDecrement) {
        tokenAddress = _tokenAddress;
        nfTokenId = _nfTokenId;
        mint = MintNFTokens(tokenAddress);
        reservePrice = _reservePrice;
        numBlockAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        seller = payable(msg.sender);
        currentOwner = seller;
        initialPrice = _reservePrice + (_numBlocksAuctionOpen * _offerPriceDecrement);
        initialBlock = block.number;
        endBlock = block.number + numBlockAuctionOpen;

        require(msg.sender == mint.ownerOf(nfTokenId),"You're not the owner of this NFT");
    }

    function currentPrice() public view returns(uint256){
        return initialPrice - ((block.number - initialBlock) * offerPriceDecrement);
    }

    function bid() public payable returns(address) {
        require(buyer == address(0x0), "Auction Concluded");
        require(msg.sender != seller, "Sellers are not allowed to buy");
        require(block.number < endBlock, "Maximum possible rounds reached and auction is closed");

        uint256 curPrice = currentPrice();
        require(msg.value >= curPrice, "Insufficient Value");

        buyer = msg.sender;

        uint256 refundAmount = msg.value - curPrice;
        if(refundAmount > 0){
            payable(msg.sender).transfer(refundAmount);
        }

        mint.safeTransferFrom(seller, buyer, nfTokenId);

        seller.transfer(msg.value - refundAmount);

        currentNFTOwner();

        return buyer;
    }

    function currentNFTOwner() public returns(address){
        currentOwner = buyer;
        return currentOwner;
    }

}