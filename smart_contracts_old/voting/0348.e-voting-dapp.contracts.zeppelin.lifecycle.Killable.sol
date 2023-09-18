// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "../ownership/Ownable.sol";

/**
 * @title Killable
 *
 * @notice Base contract that can be killed by owner.
 *         All funds in contract will be transfered to the owner.
 */
contract Killable is Ownable {

    /* Public Functions */

    /**
     * @notice Kills contract and transfer all funds to owner.
     */
    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}
