//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

//OpenZeppelin contract for better security
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
//In a recent update of Solidity the Integer type variables cannot overflow anymore. Hence, Safemath library not required for subtraction.


contract Allowance is Ownable {
    // address owner;
    
    mapping(address => uint) public allowance;
    
    // Event for declaring a change in the allowance values
    event AllowanceChanged(address indexed _who, address indexed _byWhom, uint _oldAmount, uint _newAmount);
    
    // A modifier which ensures the security of certain transactions by limiting their access to the owner
    // Not required after import of Ownable.sol
    // modifier onlyOwner() {
    //     require(msg.sender == owner, "You don't have the required privileges");
    //     _;
    // }
    
    // Setting specific allowance for each non-owner user
    function setAllowance(address _who, uint _amount) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    modifier onlyOwnerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed");
        _;
    }
    
    // Need to ensure that when owner is reducing allowance, it doesn't go below zero
    function reduceAllowance(address _who, uint _amount) internal onlyOwnerOrAllowed(_amount) {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount);
        allowance[_who] -= _amount;
    }
}