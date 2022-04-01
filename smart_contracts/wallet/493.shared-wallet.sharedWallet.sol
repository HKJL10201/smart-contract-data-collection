//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// Funds contract
contract Funds is Ownable {
    mapping(address => uint256) public funds;

    // funds set only by owner
    function setFund(address _who, uint256 _amount) public onlyOwner {
        require(
            funds[_who] <= address(this).balance,
            "Amount is more than available in the contract"
        );
        require(_amount <= address(this).balance, "Amount is too high");
        funds[_who] += _amount;
    }

    // only owner is allowed
    modifier allowed(uint256 _amount) {
        require(
            msg.sender == owner() || funds[msg.sender] >= _amount,
            "You are not allowed"
        );
        _;
    }

    // reduce funds if !owner
    function reduceFund(address _who, uint256 _amount) internal {
        funds[_who] -= _amount;
    }
}

contract SharedWallet is Ownable, Funds {
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // withdraw by only owner
    function withdrawMoney(address payable _to, uint256 _amount)
        public
        payable
        allowed(_amount)
    {
        // entered amount must < balance in the contract
        require(
            _amount <= address(this).balance,
            "Contract doesn't own enough money"
        );
        reduceFund(msg.sender, _amount);
        // transfer funds to address entered
        _to.transfer(_amount);
    }

    function pay() public payable {}
}
