// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Extension of {ERC20} that allows specifying an initial supply
 */
abstract contract ERC20FixedSupply is 
    ERC20 
{
    //=============================================================//
    //                           ERRORS                            //
    //=============================================================//

    /**
     * Error raised if initial supply is not valid
     */
    error InitialSupplyError();

    //=============================================================//
    //                         CONSTRUCTOR                         //
    //=============================================================//

    /**
     * Constructor
     *
     * @param name_          Token name
     * @param symbol_        Token symbol
     * @param initialSupply_ Initial supply
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    )
        ERC20(name_, symbol_)
    {
        if (initialSupply_ == 0) {
            revert InitialSupplyError();
        }
        _mint(_msgSender(), initialSupply_);
    }
}
