// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./presets/ERC20PresetFixedSupply.sol";

contract DVC is ERC20PresetFixedSupply {
    constructor()
    ERC20PresetFixedSupply(
        "Davinci Coin",
        "DVC",
        3000000000000000000000000,
        msg.sender
    )
    {}

    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual override(ERC721) {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     uint256 secondaryShare = msg.value / 100 * 10;
    //     payable(_creatorOf(tokenId)).transfer(secondaryShare);
    // }
}