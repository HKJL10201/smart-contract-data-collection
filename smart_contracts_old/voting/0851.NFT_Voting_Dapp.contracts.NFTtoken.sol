// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../openzeppelin-contracts/contracts/math/SafeMath.sol";
//import "../openzeppelin-contracts/contracts/utils/Address.sol";
import "../openzeppelin-contracts/contracts/utils/Counters.sol";
//import "./ERC20Token.sol";

contract NFTtoken is ERC721 {
    using SafeMath for uint256;
    //using Address for address;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    //bytes32[] candidates = [bytes32('Rama'), bytes32('Nick'), bytes32('Jose')];
    //ERC20Token ERC20TokenContract = new ERC20Token(1000, 1, candidates);
    //ERC20Token token = ERC20Token(ERC20TokenContract);    

    address payable public owner;
    mapping(bytes4 => bool) supportedInterfaces;

    mapping(uint256 => address) tokenOwners; //a mapping from NFT ID to the address that owns it
    //mapping(address => uint256) balances; //a mapping from NFT ID to the address that owns it 
    //mapping(uint256 => address) allowance; //a mapping from NFT ID to approved address
    mapping(address => mapping(address => bool)) operators; //Mapping from owner address to mapping of operator addresses.
   // mapping (uint256 => string) idToUri;
    uint8 public decimals;

    uint256[] public allValidTokenIds;
    mapping(uint256 => uint256) private allValidTokenIndex;
    string[] public allNFTNames;

    struct NFT {
        uint256 nftId;
        string name;
        address creator;
    }

    mapping(address => NFT) public nftInfo;

    //ERC20Token Erc20Contract;

    constructor() ERC721("NC NFT example", "NCNFT") {
        decimals = 0;
        //Erc20Contract = ERC20Token(tokenAddress);
    }

    function getOwner() public view returns (address) {
        return owner;
    } 

    function getCreator() public view returns (address) {
        return nftInfo[owner].creator;
    }

    function mint(string calldata nftName) external payable {
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        
        owner = msg.sender;
        nftInfo[msg.sender].nftId = newItemId;
        nftInfo[msg.sender].name = nftName;
        nftInfo[msg.sender].creator = msg.sender;

        allValidTokenIndex[newItemId] = allValidTokenIds.length;
        allValidTokenIds.push(newItemId);
        _tokenIds.increment();
    }
    
    function transferNFT(address from, address to, uint256 tokenId)  public returns (bool){
        transferFrom(from, to, tokenId);
        //Erc20Contract.transferFrom(to, nftInfo[from].creator, 10);
    }
    

    function allNFTs() public view returns (uint256[] memory) {
        return allValidTokenIds;
    }
}