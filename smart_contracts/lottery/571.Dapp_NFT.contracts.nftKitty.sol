// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract kittyNft is ERC721 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Owner of NFT
    address public owner;
    // Lottery address
    address public lottery;
    // Factory address
    address public factory;
    //nft's rank
    mapping (uint => uint) public rank;
    // Mapping from tokeId to descriptions
    mapping (uint => string) public description;
    // Mapping from address to tokedIds
    mapping(address => uint[]) public awardedNFTs;

    constructor(address _factory) ERC721("kittyNft", "kitty") {
        //ganache account used by truffle
        owner = msg.sender;
        //factory address
        factory = _factory; 
    }

    function setLotteryAddress(address _lottery) public {
        // Only the facotry is allowed to relate NFT with Try
        require(msg.sender == factory, "Only the factory can modify the association");
        lottery = _lottery; // this will be the new contract address
        //used to assign or revoke the full approval rights to the given operator
        // in this way the new lottery can manage NFTs
        _setApprovalForAll(owner, lottery, true); 
    }

    //function to mint a new nft of class X
    function mint(uint class) public
    {
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(owner, newItemId); 

        rank[class] = newItemId;
        description[class] = string(abi.encodePacked("NFT class: ", Strings.toString(class)));
       

    }

    //Return the first token id available given a class
    function getTokenOfClass(uint class) public view returns (uint){
        return rank[class];
    }

    //associate nft to the winner
    function awardItem(address player, uint256 tokenId) public {
        require(msg.sender == lottery, "Only the lottery can award tokens.");
        safeTransferFrom(owner, player, tokenId);
        for(uint i = 1; i <= 8; i++){
            if(rank[i] == tokenId){
                awardedNFTs[player].push(i);
                break;
            }

        }
        
    }

    //Return the NFTs associated to a certain player
    function getNFTsFromAddress(address addr) public view returns(string[] memory){
        uint[] memory nftWon = awardedNFTs[addr];
        string[] memory nftDescriptions;
        if (nftWon.length > 0){
            //nft descr. is just the class of the nft
            nftDescriptions = new string[](nftWon.length);
            for(uint i=0; i< nftWon.length; i++){
                nftDescriptions[i] = description[nftWon[i]];
            }
        }
        return nftDescriptions;
        //return awardedNFTs[addr];
    }
}
