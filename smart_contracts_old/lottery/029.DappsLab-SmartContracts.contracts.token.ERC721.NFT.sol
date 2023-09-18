// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./presets/ERC721PresetMinterPauserAutoId.sol";

//import "./presets/ERC721PresetMinterPauserAutoId.sol";

contract NFT is ERC721PresetMinterPauserAutoId {
    constructor()
    ERC721PresetMinterPauserAutoId(
        "Davinci Token",
        "NFT",
        "ipfs://QmQsst5yczxQ1eZJBZSDEBdbM6reAUGE33pzvhbDsYAjb7/"
    )
    {}
}
