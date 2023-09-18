// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafePayment/SafePayment.sol";

// SafePayment mock contract
contract SafePaymentMock is SafePayment {
    constructor() {}

    receive() external payable {}

    function sendETH(address to) public payable returns (bool) {
        return safeSendETH(to, msg.value);
    }

    function withdraw(address to) public returns (bool success) {
        return getUnclaimed(to);
    }
}
