//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface MintNFTokens{
     function safeTransferFrom(address from, address to, uint256 tokenId) external;
     function ownerOf(uint256 tokenId) external view returns(address owner);
}

interface MintERC20Tokens{
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract NFTDutchAuction is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    address payable seller;
    address public currentOwner;
    address public buyer;

    uint256 reservePrice;
    uint256 numBlockAuctionOpen;
    uint256 offerPriceDecrement;
    uint256 initialPrice;
    
    uint256 initialBlock;
    uint256 endBlock;

    uint256 nfTokenId;
    address tokenAddress;
    address erc20TokenAddress;
    MintNFTokens mint;
    MintERC20Tokens mintERC20;

    // constructor(address _tokenAddress, uint256 _nfTokenId, uint256 _reservePrice, uint256 _numBlocksAuctionOpen, uint256 _offerPriceDecrement)
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(address _erc20TokenAddress, address _erc721TokenAddress, uint256 _nftTokenId, uint256 _reservePrice, uint256 _numBlocksAuctionOpen, uint256 _offerPriceDecrement) 
        public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        tokenAddress = _erc721TokenAddress;
        erc20TokenAddress = _erc20TokenAddress;
        nfTokenId = _nftTokenId;
        mint = MintNFTokens(tokenAddress);
        mintERC20 = MintERC20Tokens(erc20TokenAddress);
        reservePrice = _reservePrice;
        numBlockAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        seller = payable(msg.sender);
        currentOwner = seller;
        initialPrice = _reservePrice + (_numBlocksAuctionOpen * _offerPriceDecrement);
        initialBlock = block.number;
        endBlock = block.number + numBlockAuctionOpen;
        buyer = address(0x0);

        require(msg.sender == mint.ownerOf(nfTokenId),"You're not the owner of this NFT");
    }

    function currentPrice() public view returns(uint256){
        return initialPrice - ((block.number - initialBlock) * offerPriceDecrement);
    }

    function bid(uint256 bidAmount) public payable returns(address) {
        require(buyer == address(0x0), "Auction Concluded");
        require(msg.sender != seller, "Sellers are not allowed to buy");
        require(block.number < endBlock, "Maximum possible rounds reached and auction is closed");

        uint256 curPrice = currentPrice();
        require(mintERC20.balanceOf(msg.sender) >= bidAmount, "Insufficient Gunnercoin in your account");

        require(bidAmount >= curPrice, "Insufficient Value");

        buyer = payable(msg.sender);

        uint256 refundAmount = bidAmount - curPrice;
        // if(refundAmount > 0){
        //     mintERC20.transfer( msg.sender, refundAmount);
        // }

        mint.safeTransferFrom(seller, buyer, nfTokenId);

        mintERC20.transferFrom(buyer, seller, (bidAmount - refundAmount));

        currentNFTOwner();

        return buyer;
    }

    function currentNFTOwner() public returns(address){
        currentOwner = buyer;
        return currentOwner;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}