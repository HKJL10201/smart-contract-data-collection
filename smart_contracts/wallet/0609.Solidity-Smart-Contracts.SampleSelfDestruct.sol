// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract StartStopUpdateExample {
    receive() external payable {}

    function destroySmartContract() public {
        selfdestruct(payable(msg.sender)); // the selfdestruct keyword is used to destroy a contract and transfer its remaining Ether balance to a designated address. The selfdestruct function is typically used to implement upgradeable or self-destructing contracts, where the contract owner may choose to terminate the contract and transfer any remaining funds to a specific address.
    } // We wrote payable because it will help to transfer the funds to desired account.
}