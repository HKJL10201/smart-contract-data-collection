// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "hardhat/console.sol";

/**
 * @title BadReceiver
 */

// Mock contract that reverts when it receives ether
contract BadReceiver {
    // The receive function is a special function in Solidity that is automatically called
    // when the contract receives ether. In this case, it reverts the transaction with
    // the specified error message.
    receive() external payable {
        revert("Don't send me ether!");
    }
}
