// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Royalties/ERC2981Royalties.sol";

contract NFT is ERC721URIStorage, AccessControl, ERC2981Royalties {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => bytes32) private _tokenHash;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address private immutable _auctionImp;
    address internal immutable _projectTreasury;

    constructor(
        string memory name,
        string memory symbol,
        address auction,
        address projectTreasury
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _auctionImp = auction;
        _projectTreasury = projectTreasury;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, ERC2981Royalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address author,
        string memory nftURI,
        bytes32 hash,
        uint256 royaltyValue,
        bool setApprove
    ) internal returns (uint256) {
        uint256 id = _tokenIds.current();
        _tokenIds.increment();

        _mint(author, id);
        _setTokenURI(id, nftURI);
        _tokenHash[id] = hash;
        _setTokenRoyalty(id, author, royaltyValue);

        if (setApprove) {
            _approve(_auctionImp, id);
        }

        return id;
    }

    function mintNFT(
        address author,
        string memory nftURI,
        bytes32 hash,
        uint256 royaltyValue,
        bool setApprove
    ) external virtual onlyRole(MINTER_ROLE) returns (uint256) {
        return mint(author, nftURI, hash, royaltyValue, setApprove);
    }

    function tokenHash(uint256 tokenId) public view returns (bytes32) {
        return _tokenHash[tokenId];
    }
}
