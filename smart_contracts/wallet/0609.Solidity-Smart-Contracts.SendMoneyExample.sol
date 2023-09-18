// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SendWithdrawMoney {
    uint public balanceReceived;

    function deposit() public payable{
        balanceReceived += msg.value;
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance; // Returning the balance of smart contract
    }

    function withdrawAll() public {
        address payable to = payable(msg.sender);

        to.transfer(getContractBalance()); // we get the contract balance and transfer it to the person who call the smart contract
    }

    function withdrawToAddress(address payable to) public {
        to.transfer(getContractBalance());
    }
}
