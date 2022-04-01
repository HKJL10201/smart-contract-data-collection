//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allowance is Ownable {
    
    event AllowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount, uint _newAmount);
    
    /*
     *Used to keep track of every accounts allowed allowance 
     */
    mapping(address => uint) public allowance;
    
    /*
     *This function internally calls owner function from openzeppelin-contracts
     *This function returns true, if Any function is invoked by owner, else
     * it returns false.
     */
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    /*
     *This function is used to add allowance
     */
    function addAllowance(address _who, uint _amount) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _amount);
        allowance[_who] = _amount;
    }
    
    /*
     *This function is used to remove allowance
     */
    function reduceAllowance(address _who, uint _amount) internal ownerOrAllowed(_amount) {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount);
        allowance[_who] -= _amount;
    }

    /*
     *This function is used to check the function invocation by either owner or 
     *by any other accounts
     */
    modifier ownerOrAllowed(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed!");
        _;
    }
}