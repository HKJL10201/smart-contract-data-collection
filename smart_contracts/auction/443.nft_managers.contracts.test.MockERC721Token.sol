// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Mock ERC721 token
 */
contract MockERC721Token is 
    ERC721 
{
    //=============================================================//
    //                           CONSTANTS                         //
    //=============================================================//

    // NFT name
    string constant private NFT_NAME = "Mock ERC721 Token";
    // NFT symbol
    string constant private NFT_SYMBOL = "MT";

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     */
    constructor()
        ERC721(NFT_NAME, NFT_SYMBOL)
    {}

    //=============================================================//
    //                          FUNCTIONS                          //
    //=============================================================//

    /**
     * Mint token `id_` to `to_`
     * @param to_ Receiver address
     * @param id_ Token ID
     */
    function mintTo(
        address to_,
        uint256 id_
    ) public {
        _safeMint(to_, id_);
    }
}
