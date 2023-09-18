// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "../NftsSeller.sol";


/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  To test the contract upgradeability
 */
contract NftsSellerUpgraded is 
    NftsSeller 
{
    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    /**
     * New function to check if the contract has been upgraded 
     */
    function isUpgraded() public pure returns (bool) {
        return true;
    }
}
