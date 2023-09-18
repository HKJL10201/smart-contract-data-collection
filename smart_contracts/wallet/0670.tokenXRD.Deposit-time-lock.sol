//SPDX-License-Identifier: GPL 3.0
pragma solidity >=0.7.0 <0.9.0;

import './Ownable.sol';

contract DepositTimeLocked is Ownable {

    mapping(address => uint256) balances;
    mapping(address => uint256) lockUntil;

    function deposit() public payable returns (bool) {
        require(msg.value >= 1 ether, "Insuficient ether to make this transaction");
        balances[msg.sender] += msg.value;
        lockUntil[msg.sender] += block.timestamp + 30 seconds;
        return true;
    }

    function getBalance() public view returns (uint256) {
        address contractAddress = (address(this));
        return contractAddress.balance;
    }

    function withdraw() public {
        require(block.timestamp > lockUntil[msg.sender], "You have to wait for make this transaction");
        require(balances[msg.sender] > 0, "Insuficient ether to make this transaction");
        uint256 amountToTransfer = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amountToTransfer);
    }

    function withdrawAll(address _recipient) public isOwner returns (bool) {
        uint256 myBalance = getBalance();
        payable(_recipient).transfer(myBalance);
        return true;
    }

}