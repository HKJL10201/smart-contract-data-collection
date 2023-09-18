// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    //tokenId => address => tip balance
    mapping(uint256 => mapping(address => uint256)) public tokenOnwerTipBalance;

    mapping(uint256 => mapping(address => bool)) private liked;

    mapping(uint256 => uint256) public likes;

    constructor() ERC721("MyNFT", "MNFT") {}

    /// @dev mint function for arts
    function safeMint(address to, string calldata uri) public onlyOwner {
        require(to != address(0), "Invalid minter address");
        require(bytes(uri).length > 0);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /// @dev function to tip owner of an nft
    function tipNftOwner(uint256 tokenId)
        public
        payable
        returns (bool success)
    {
        require(owner() != msg.sender, "Owner can't tip his arts");
        require(msg.value == 0.05 ether, "You can tip only 0.5 CELO at a time");
        address tokenOwner = ownerOf(tokenId);

        tokenOnwerTipBalance[tokenId][tokenOwner] += msg.value;

        (success, ) = payable(tokenOwner).call{value: msg.value}("");
        require(success, "Failed to send");
    }

    /**
     * @dev allow users to like or dislike an art
     */
    function likeOrDislike(uint256 tokenId) public {
        require(_exists(tokenId), "Query of nonexistent tokenId");
        if (liked[tokenId][msg.sender]) {
            liked[tokenId][msg.sender] = false;
            likes[tokenId]--;
        } else {
            liked[tokenId][msg.sender] = true;
            likes[tokenId]++;
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

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
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
