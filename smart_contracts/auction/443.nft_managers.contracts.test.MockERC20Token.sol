// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "./ERC20FixedSupply.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Mock ERC20 token
 */
contract MockERC20Token is 
    ERC20FixedSupply 
{
    //=============================================================//
    //                           CONSTANTS                         //
    //=============================================================//

    // Token name
    string constant private TOKEN_NAME = "Mock ERC20 Token";
    // Token symbol
    string constant private TOKEN_SYMBOL = "MT";

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     * @param initialSupply_ Initial supply
     */
    constructor(
        uint256 initialSupply_
    )
        ERC20FixedSupply(TOKEN_NAME, TOKEN_SYMBOL, initialSupply_)
    {}
}
