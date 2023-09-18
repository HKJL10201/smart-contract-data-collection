//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable {
    using SafeMath for uint;

    address public _owner;
    mapping(address => uint) allowance;

    event allowancechanged(
        address indexed _for,
        address indexed _by,
        uint _oldamount,
        uint _newamount
    );

    constructor() {
        _owner = msg.sender;
    }

    function allowances(address _who, uint _amount) public onlyOwner {
        emit allowancechanged(_who, msg.sender, allowance[_who], _amount);
        _amount = _amount * 1 ether;
        allowance[_who] = _amount;
    }

    modifier ownerorAllowed(uint _amount) {
        require(
            msg.sender == _owner || allowance[msg.sender] >= _amount,
            "You are not allowed"
        );
        _;
    }

    function reduce_allowance(address _who, uint _amount) internal {
        emit allowancechanged(
            _who,
            msg.sender,
            allowance[_who],
            allowance[_who] - _amount
        );
        allowance[_who] = allowance[_who].sub(_amount);
    }
}

contract Miniwallet is Allowance {
    event moneysent(address indexed _beneficiary, uint amount);
    event moneyreceived(address indexed From, uint amount);

    function renounceOwnership() public pure override {
        revert("Cannot change Ownership");
    }

    function withdrawal(address payable _to, uint _amount)
        public
        ownerorAllowed(_amount)
    {
        _amount = _amount * 1 ether;
        if (msg.sender != _owner) {
            reduce_allowance(msg.sender, _amount);
        }
        emit moneysent(_to, _amount);
        _to.transfer(_amount);
    }

    receive() external payable {
        emit moneyreceived(msg.sender, msg.value);
    }

    function allowancebalance() public view returns (uint) {
        return allowance[msg.sender];
    }

    function balance() public view returns (uint) {
        return address(this).balance;
    }
}
