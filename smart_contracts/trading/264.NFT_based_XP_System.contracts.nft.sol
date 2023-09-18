// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./nft_explorer.sol";

contract nft is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _iterationCounter;
    Counters.Counter private _tokenIdCounter;
    string private publicURI;
    address private _owner;
    address public _nftExplorerAddress; //NFT EXPLORER ADDRESS(!!2) --- !!0

    mapping(uint256 => mapping(address => uint256)) private req_track;

    constructor() ERC721("XpNFT", "XNFT") {}

    function safeMint(address to, string memory uri) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        nft_explorer(_nftExplorerAddress).mapNFT(to, 0); ///XP VALUE IS JUST HARDCODED --- !!1
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return publicURI;
    }


    function set_public_URI(string memory URI) public onlyOwner {
        publicURI = URI;
    }

    function verify_URI_access(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Ownable: caller is not the owner"
        );
        req_track[_iterationCounter.current()][msg.sender] = block.timestamp;
    }

    function get_private_URI(address owner, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            (req_track[_iterationCounter.current()][owner]) > 0,
            "block time has been changed, please verify access again."
        );
        require(ownerOf(tokenId) == owner, "Ownable: caller is not the owner");
        return super.tokenURI(tokenId);
    }

    function next_itration() public {
        _iterationCounter.increment();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /////////////////////////////////////////////THIS FUNCTION IS JUST FOR TEST PURPOSES (!!0) --- !!2
    function set_nft_explorer_address(address nft_explorer_address) public onlyOwner {
        _nftExplorerAddress = nft_explorer_address;
    }
}
