// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ContractOne {
    mapping (address => uint) public addressBalances;

    function deposit() public payable {
        addressBalances[msg.sender] += msg.value;
    }

    receive() external payable {
        deposit();
    }
}


contract ContractTwo{
    receive() external payable{}

    function depositOnContractOne(address _contractOne) public{
        // bytes memory payload = abi.encodeWithSignature("deposit()"); // It is taking that particular function signature and creating it for you and putting it into a bytes. 
        // ContractOne one = ContractOne(_contractOne);
        (bool success, ) = _contractOne.call{value: 10, gas: 100000}(""); // This will tell you if the low level call was successful and then we can just require the success.
        require(success);
    }
}