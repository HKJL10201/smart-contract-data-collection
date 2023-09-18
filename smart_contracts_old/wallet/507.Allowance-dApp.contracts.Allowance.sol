// SPDX-License-Identifier: MIT
pragma solidity ^0.5.13;

/**
 * @title Allowance
 * @dev allows deployer to set allowance for users of a shared wallet
 */

import "./safemath.sol";

contract Allowance {
    
    using SafeMath for uint;
    
    event AllowanceChanged(address indexed _forWho, address indexed _fromWhom, uint _oldAmount, uint _newAmount);
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function displayOwner() view public returns(address) {
        return owner;
    }
    
    mapping(address => uint) public allowance;
    
    modifier isOwner() {
        require(owner == msg.sender, "Must be owner.");
        _;
    }
    
    function addAllowance(address _who, uint _amount) public isOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    modifier ownerOrAllowed(uint _amount) {
        require(owner == msg.sender || allowance[msg.sender] >= _amount, "You are not allowed");
        _;
    }
    
    function reduceAllownace(address _who, uint _amount) internal {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who].sub(_amount));
        allowance[_who] = allowance[_who].sub(_amount);
    }
}
