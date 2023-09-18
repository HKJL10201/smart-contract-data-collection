//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold;

    constructor() ERC721("NFTMarketplace","NFTM"){
        owner = payable(msg.sender);

    }

    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    struct ListedToken{
        uint tokenId;
        address payable owner;
        address payable seller;
        uint price;
        ListingStatus status;
    }

    mapping (uint => ListedToken) private idToListedToken;

    //create Token
    function createToken(string memory tokenURI, uint price) public payable returns (uint){
        require(price>0,"Token Price has to be positive");
        _tokenIds.increment();
        uint curId = _tokenIds.current();
        _safeMint(msg.sender, curId);
        _setTokenURI(curId, tokenURI);
        createListedToken(curId,price);

        return curId;
    }

    function createListedToken(uint tokenId, uint price) private {
        idToListedToken[tokenId] =ListedToken (
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            ListingStatus.Active
        );

        //Let smart contract own this NFT (approve contract)
        _transfer(msg.sender, address(this), tokenId);
    }

    function getAllTokens() public view returns (ListedToken[] memory) {
        uint count = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](count);
        uint curId = 0;

        for (uint i =1; i< count; i++){
            ListedToken storage cur = idToListedToken[i];
            if (cur.status == ListingStatus.Active){
                tokens[curId]= cur;
                curId++;
            }
            
        }
        return tokens;
    }

    function getMyTokens() public view returns (ListedToken[] memory) {
        uint count = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](count);
        uint curId = 0;

        for (uint i =1; i< count; i++){
            ListedToken storage cur = idToListedToken[i];
            if (cur.owner == msg.sender || cur.seller == msg.sender){
                tokens[curId]= cur;
                curId++;
            }  
        }
        return tokens;
    }

    function buyToken(uint tokenId) external payable{
        ListedToken storage token = idToListedToken[tokenId];
        require(token.status == ListingStatus.Active,"Listing is not active");
        require(msg.sender != token.seller,"Seller cannot be buyer");
        require(msg.value >= token.price, "Insufficient payment");
        token.status=ListingStatus.Sold;
        token.seller = payable(msg.sender);

        _transfer(address(this), msg.sender, token.tokenId);
        approve(address(this),tokenId);
        payable(token.seller).transfer(token.price);
    }

    function cancel(uint tokenId) public {
        ListedToken storage token = idToListedToken[tokenId];
        require(token.status == ListingStatus.Active,"Listing is not active");
        require(msg.sender == token.seller,"The canceler needs to be the seller");
        token.status=ListingStatus.Cancelled;
        _transfer(address(this), msg.sender, token.tokenId);
    }


}
