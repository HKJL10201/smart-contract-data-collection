// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

//Initializable,
contract MintNFT is
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    uint256 public maxSupply;

    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply;
        require(maxSupply >= 1, "Max token supply must be greater than 0"); // throws error if max supply is set to 0
        require(
            maxSupply <= 500,
            "Max token supply must be less than or equal to 500"
        ); // throws error if max supply is set to a number greater than 500
    }

    // mints the nft
    function safeMint(address to, string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current(); // sets tokenId to the current number in the counter
        require(tokenId <= (maxSupply - 1), "Max number of tokens minted"); // checks if the number of minted nfts have surpassed the max supply we set earlier
        _tokenIdCounter.increment(); // increments token counter for every successful nft mint
        _safeMint(to, tokenId); // mints token to owners address and sets it to specific tokenId
        _setTokenURI(tokenId, uri); // links tokenId with uri
    }

    /*
    // fn to initialize the nft to the parameters set below
    function initialize(uint256 _maxSupply) public initializer {
        maxSupply = _maxSupply;
        require(maxSupply >= 1, "Max token supply must be greater than 0"); // throws error if max supply is set to 0
        require(
            maxSupply <= 500,
            "Max token supply must be less than or equal to 500"
        ); // throws error if max supply is set to a number greater than 500
        __ERC721_init("Vickens NFT", "VNFT"); // initializes name and symbol
        __ERC721URIStorage_init();
        __Ownable_init();
    }
    */

    // The following functions are overrides required by Solidity

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
