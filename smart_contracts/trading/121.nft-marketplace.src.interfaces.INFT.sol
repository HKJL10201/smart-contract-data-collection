// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface INFT {
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function supportsInterface(bytes4 interfaceID) external returns (bool);
}