// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract ExampleExceptionRequire {
    mapping (address => uint) public balanceReceived;

    function receiveMoney() public payable{
        balanceReceived[msg.sender] += msg.value;
    }

    function withdrawMoney(address payable _to, uint _amount) public {
        require(_amount <= balanceReceived[msg.sender], "Error");
            balanceReceived[msg.sender] -= _amount;
            _to.transfer(_amount);
    }

}