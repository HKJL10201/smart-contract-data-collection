// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <=0.9.0;

contract SendEther {
    uint public totalBalance;

    function receiveEthers() external payable {
        totalBalance += msg.value;
    }

    function sendEthers(
        uint256 transferAmount,
        address receiverAddress
    ) external payable {
        require(
            transferAmount > 0,
            "Amount to be transfered must be greater that 0."
        );
        require(
            msg.sender.balance >= transferAmount,
            "Insufficinet balance in your account!"
        );
        require(receiverAddress != address(0), "Invalid address provided");

        payable(receiverAddress).transfer(transferAmount);
    }

    receive() external payable {}
}
