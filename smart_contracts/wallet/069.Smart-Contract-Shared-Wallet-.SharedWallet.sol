//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Allowance.sol";

contract SharedWallet is Allowance {

    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(address(this).balance >= _amount, "Smart contract does not have sufficient funds!");
        if(!isOwner()) {
            reduce(msg.sender, _amount);
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }

    function renounceOwnership() public override view onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract;
    }

    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}

// project from https://ethereum-blockchain-developer.com/

