// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Mock ERC1155 token
 */
contract MockERC1155Token is 
    ERC1155 
{
    //=============================================================//
    //                           CONSTANTS                         //
    //=============================================================//

    // NFT name
    string constant private NFT_NAME = "Mock ERC1155 Token";
    // NFT symbol
    string constant private NFT_SYMBOL = "MT";

    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Contract name
    string public name;
    /// Contract symbol
    string public symbol;

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     */
    constructor()
        ERC1155("")
    {
        name = NFT_NAME;
        symbol = NFT_SYMBOL;
    }

    //=============================================================//
    //                          FUNCTIONS                          //
    //=============================================================//

    /**
     * Mint `amount_` of token `id_` to `to_`
     * @param to_     Receiver address
     * @param id_     Token ID
     * @param amount_ Token amount
     */
    function mint(
        address to_, 
        uint256 id_, 
        uint256 amount_
    ) public {
        _mint(to_, id_, amount_, "");
    }
}
