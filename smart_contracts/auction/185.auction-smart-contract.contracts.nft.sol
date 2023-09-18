// SPDX-License-Identifier: GPL-3.0


pragma solidity 0.8.9;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// AN NFT where only Admin can mint to users
// The NFT has a max supply of 5
contract NFT is ERC721URIStorage {
    address owner;
    constructor() ERC721("MyNFT", "MNF"){
        owner = msg.sender;

    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 MAX_SUPPLY = 5;
    string nfturi = "https://ipfs.io/ipfs/QmT5cGgUZeMgNS6poZSPf7ebcnswaf5vjuP4F8DAAKp3gw?filename=metadata.json";

    modifier onlyOwner{
        require(msg.sender == owner, "You are not eligible to mint this nft");

        _;
    }

    function safeMint(address to) external onlyOwner returns(uint256) {
        uint256 newItemId = _tokenIds.current();
        require( newItemId <= MAX_SUPPLY, "All nft have been minted");
        _mint(to, newItemId);
        _setTokenURI(newItemId, nfturi);

        _tokenIds.increment();
        return (newItemId);
    }

}