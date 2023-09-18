// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./presets/ERC721PresetMinterPauserAutoId.sol";

//import "./presets/ERC721PresetMinterPauserAutoId.sol";

contract NFT is ERC721PresetMinterPauserAutoId {
    constructor()ERC721PresetMinterPauserAutoId(
        "Passport","T2P","127.0.0.1:8080/ipfs/"
    ){

    }
}
