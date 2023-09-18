// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                            IMPORTS                          //
//=============================================================//
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Interface for any contract that wants to support ERC20 transfers from NFT manager contracts
 */
interface IERC20Receiver
{
    //=============================================================//
    //                       PUBLIC FUNCTIONS                      //
    //=============================================================//

    /**
     * Function called by NFT manager contracts when ERC20 tokens are transferred to
     * payment address, in case it is a contract.
     * It must return its Solidity selector to confirm the token transfer.
     * 
     * @param token_  Token address
     * @param amount_ Token amount
     * @return Function selector, i.e. `IERC20Receiver.onERC20Received.selector`
     */
    function onERC20Received(
        IERC20 token_,
        uint256 amount_
    ) external returns (bytes4);
}
