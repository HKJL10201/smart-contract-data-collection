pragma solidity >=0.6.0 <0.7.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YourCollectible is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bool public paused = false;

    constructor(bytes32[] memory assetsForSale)
        public
        ERC721("ENSO NFT", "ENSO")
    {
        _setBaseURI("https://ipfs.io/ipfs/");
        for (uint256 i = 0; i < assetsForSale.length; i++) {
            forSale[assetsForSale[i]] = true;
        }
    }

    //this marks an item in IPFS as "forsale"
    mapping(bytes32 => bool) public forSale;
    //this lets you look up a token by the uri (assuming there is only one of each uri for now)
    mapping(bytes32 => uint256) public uriToTokenId;

    function ownerMintItem(string memory tokenURI)
        public
        payable
        onlyOwner
        returns (uint256)
    {
        bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

        //make sure they are only minting something that is marked "forsale"
        require(!paused, "sale is paused");
        require(forSale[uriHash], "NOT FOR SALE");
        console.log("Sender balanc tokens ww", msg.value);
        console.log("balance:", address(this).balance);
        console.log("#ofCollectibles:", balanceOf(msg.sender));
        forSale[uriHash] = false;

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);
        _setTokenURI(id, tokenURI);

        uriToTokenId[uriHash] = id;

        return id;
    }

    function mintItem(string memory tokenURI) public payable returns (uint256) {
        bytes32 uriHash = keccak256(abi.encodePacked(tokenURI));

        //make sure they are only minting something that is marked "forsale"
        require(!paused, "sale is paused");
        require(forSale[uriHash], "NOT FOR SALE");
        require(msg.value >= 0.04 ether, "Value below price");
        console.log("Sender balanc tokens ww", msg.value);
        console.log("balance:", address(this).balance);
        console.log("#ofCollectibles:", balanceOf(msg.sender));
        forSale[uriHash] = false;

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);
        _setTokenURI(id, tokenURI);

        uriToTokenId[uriHash] = id;

        return id;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}
