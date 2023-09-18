// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//=============================================================//
//                           IMPORTS                           //
//=============================================================//
import "../IERC20Receiver.sol";

/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Mock ERC20 receiver
 */
contract MockERC20Receiver is 
    IERC20Receiver 
{
    //=============================================================//
    //                            STORAGE                          //
    //=============================================================//

    /// Received flag
    bool public received;

    //=============================================================//
    //                          FUNCTIONS                          //
    //=============================================================//

    /**
     * Function called by the NFT manager contracts when ERC20 tokens are transferred to
     * payment address.
     * It must return its Solidity selector to confirm the token transfer.
     * 
     * @param token_  Token address
     * @param amount_ Token amount
     * @return Function selector, i.e. `IERC20Receiver.onERC20Received.selector`
     */
    function onERC20Received(
        IERC20 token_,
        uint256 amount_
    ) external override returns (bytes4) {
        received = true;
        return IERC20Receiver.onERC20Received.selector;
    }
}

/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Mock ERC20 receiver with `onERC20Received` that returns a wrong value 
 */
contract MockERC20ReceiverRetValErr is 
    IERC20Receiver 
{
    //=============================================================//
    //                          FUNCTIONS                          //
    //=============================================================//

    /**
     * Function called by the NFT manager contracts when ERC20 tokens are transferred to
     * payment address.
     * It must return its Solidity selector to confirm the token transfer.
     * 
     * @param token_  Token address
     * @param amount_ Token amount
     * @return Function selector, i.e. `IERC20Receiver.onERC20Received.selector`
     */
    function onERC20Received(
        IERC20 token_,
        uint256 amount_
    ) external override returns (bytes4) {
        return "";
    }
}

/**
 * @author Emanuele Bellocchia (ebellocchia@gmail.com)
 * @title  Mock ERC20 receiver that does not implement `onERC20Received`
 */
contract MockERC20ReceiverNotImpl 
{}
