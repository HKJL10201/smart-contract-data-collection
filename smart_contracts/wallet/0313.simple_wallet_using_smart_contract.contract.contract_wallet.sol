// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract contract_wallet {

    uint public cashRecieved;

    function deposit() public payable {
        cashRecieved += msg.value;
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withDrawAll() public {
        address payable to = payable(msg.sender);
        to.transfer(getContractBalance());
    }

    function withDrawToAddress(address payable _address) public {

        _address.transfer(getContractBalance());
    }


}