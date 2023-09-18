// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KittyNFT is ERC721 {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Owner of NFT
    address public owner;
    // Lottery address
    address public lottery;
    // Factory address
    address public factory;
    // Mapping from classes to tokenId
    mapping(uint => uint) public classes;
    // Mapping from tokeId to descriptions
    mapping(uint => string) public descriptions;
    // Mapping from address to tokedIds
    mapping(address => uint[]) public awardedNFTs;

    constructor(address _factory) ERC721("KittyNFT", "KTTY") {
        owner = msg.sender; // this is ganache account used in truffle migrate
        factory = _factory; // this is the factory address
    }

    /**
     * @dev Set the reference to the active Try contract
     * @param _lottery: address of Try contract
     */
    function setLotteryAddress(address _lottery) public {
        // Only the facotry is allowed to relate NFT with Try
        require(msg.sender == factory, "Only the factory can modify the association");
        lottery = _lottery; // this will be the new contract address
        _setApprovalForAll(owner, lottery, true); // in this way the new lottery can manage NFTs
    }
    
    /**
     * @dev Mint a new NFT of a given class
     * @param class: NFT's class
     */
    function mint(uint class) public returns (uint256){
        uint256 newItemId = _tokenIds.current();

        _tokenIds.increment();
        _safeMint(owner, newItemId);

        classes[class] = newItemId;
        descriptions[newItemId] = string(abi.encodePacked("NFT of class: ", Strings.toString(class)));

        return newItemId;
    }
    
    /**
     * @dev Return the first token id available given a class
     * @param class: NFT's class
     */
    function getTokenFromClass(uint class) public view returns(uint){
        return classes[class];
    }

    /**
     * @dev Associate NFT to the winner
     * @param player: Winner
     * @param tokenId: Id of the token to associate
     */
    function awardItem(address player, uint256 tokenId) public {
        require(msg.sender == lottery, "Only the lottery can award tokens.");
        safeTransferFrom(owner, player, tokenId);
        awardedNFTs[player].push(tokenId);
    }

    /**
     * @dev Return the NFTs associated to a certain player
     * @param addr: address representing the user
     */
    function getNFTsFromAddress(address addr) public view returns(string[] memory){
        uint[] memory nftWon = awardedNFTs[addr];
        string[] memory nftDescriptions;
        if (nftWon.length > 0){
            nftDescriptions = new string[](nftWon.length);
            for(uint i=0; i< nftWon.length; i++){
                nftDescriptions[i] = descriptions[nftWon[i]];
            }
        }
        return nftDescriptions;
    }
}