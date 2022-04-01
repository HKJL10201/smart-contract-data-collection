// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
    event AllowanceChanged(address indexed _to, address indexed _from, uint _previousAmount, uint _currentAmount);

    using SafeMath for uint;

    mapping(address => uint) public allowance;

    function isOwner() public view returns (bool) {
        return owner() == msg.sender;
    }

    modifier ownerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed");
        _;
    }

    function reduceAllowance(address _who, uint _amount) internal {
        uint previousAmount = allowance[_who];
        allowance[_who] = allowance[_who].sub(_amount, "failed to complete the operation");

        emit AllowanceChanged(_who, msg.sender, previousAmount, allowance[_who]);
    }

    function setAllowance(address _to, uint _amount) public onlyOwner {
        uint previousAmount = allowance[_to];

        allowance[_to] = _amount;

        emit AllowanceChanged(_to, msg.sender, previousAmount, allowance[_to]);
    }

    function addAllowance(address _to, uint _amount) public onlyOwner {
        uint previousAmount = allowance[_to];

        allowance[_to] = allowance[_to].add(_amount);

        emit AllowanceChanged(_to, msg.sender, previousAmount, allowance[_to]);
    }

    function subAllowance(address _to, uint _amount) public onlyOwner {
        reduceAllowance(_to, _amount);
    }
}
contract Wallet is Allowance {
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    function withdraw(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= getBalance(), "not enough founds");

        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        
        _to.transfer(_amount);

        emit MoneySent(_to, _amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function renounceOwnership() override pure public {
        revert("Can't renounce ownership");
    }

    receive () external payable  {
        emit MoneyReceived(msg.sender, msg.value);
    }
}