// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "../node_modules/erc721a/contracts/ERC721A.sol";

contract Lighthouse is ERC721A {
    address private _owner;

    constructor() ERC721A("Lighthouse", "LTH") {
        _owner = msg.sender;
    }

    function mint(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    function burn(uint256 tokenId) external onlyOwner {
        super._burn(tokenId);
    }

    function burnMultiple(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            super._burn(tokenIds[i]);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://lighters.live/api/nft/";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        return string.concat(super.tokenURI(tokenId), ".json");
    }

    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "Only the contract owner can call this function"
        );
        _;
    }
}
