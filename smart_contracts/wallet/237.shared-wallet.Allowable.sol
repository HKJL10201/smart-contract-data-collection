//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Ownable contract from OpenZeppelin is providing access mechanism where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions by 'onlyOwner' modifier.
 */
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
 * @dev Allowable implements mechanism to control access to any countable goods by 
 * 'onlyAllowed' modifier.
 */
contract Allowable is Ownable {
    mapping (address => uint) private allowance; // allowance ledger

    event AllowanceChanged(address indexed _who, address _by, uint _oldBalance, uint _newBalance);

    /**
     * @dev Allows owner or anyone with enough allowance to call specified functions
     */
    modifier onlyAllowed(uint _amount) {
        require(msg.sender == owner() || allowance[msg.sender] >= _amount, "Allowable: You are not allowed");
        _;
    }

    /**
     * @dev Sets allowance to specified amount, only owner may call it
     */
    function setAllowance(address _who, uint _allowance) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _allowance);
        allowance[_who] = _allowance;
    }

    /**
     * @dev Reduces allowance by specified amount
     * @param _amount Amount of ether allowance to reduce
     */
    function reduceAllowance(address _who, uint _amount) internal onlyAllowed(_amount) {
        require(_amount <= allowance[msg.sender], "Allowable: Amount to reduce allowance is higher than allowance");
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] -= _amount);
        allowance[msg.sender] -= _amount;
    }
}