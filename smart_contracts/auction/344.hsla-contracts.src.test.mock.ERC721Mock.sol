// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

contract ERC721Mock is ERC721Upgradeable, ERC721EnumerableUpgradeable {
    function initialize(string memory name, string memory symbol) public initializer {
        ERC721Upgradeable.__ERC721_init(name, symbol);
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
