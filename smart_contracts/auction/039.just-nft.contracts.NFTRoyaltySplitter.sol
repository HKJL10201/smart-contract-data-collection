// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NFT.sol";
import "./Royalties/RoyaltySplitter.sol";

contract NFTRoyaltySplitter is NFT {
    constructor(
        string memory name,
        string memory symbol,
        address auction,
        address projectTreasury
    ) NFT(name, symbol, auction, projectTreasury) {} // solhint-disable-line no-empty-blocks

    function mintNFT(
        address author,
        string memory nftURI,
        bytes32 hash,
        uint256 royaltyValue,
        bool setApprove
    ) external override onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 id = mint(author, nftURI, hash, royaltyValue, setApprove);
        RoyaltySplitter royaltyAddr = new RoyaltySplitter(
            author,
            _projectTreasury
        );
        _setTokenRoyalty(id, address(royaltyAddr), royaltyValue);
        return id;
    }
}
