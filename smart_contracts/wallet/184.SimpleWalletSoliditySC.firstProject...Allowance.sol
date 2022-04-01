//SPDX-License-Identifier: IIESTS
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol" ;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable{
    using SafeMath for uint;
    mapping (address => uint) public allowance;
    event AllowanceChanged(address indexed _forWho,address indexed _byWhom,uint _oldAmount, uint _newAmount);
    /*
    constructor () public{
        owner = msg.sender;
    }
    // --------------- This modifier is already present in Ownable.sol ---------------
    modifier onlyOwner(){
        require(owner == msg.sender,'You are not Owner');
        _;
    } 
    */
    function isOwner() internal view returns(bool){
        return owner() == msg.sender;
    }
    modifier ownerOrAllowed(uint _amount){
        require(isOwner() || allowance[msg.sender]>=_amount,"You are not allowed");
        _;
    }
    function addAllowance(address _who,uint _amount)public onlyOwner{
        emit AllowanceChanged(_who,msg.sender,allowance[_who],_amount);
        allowance[_who]=_amount;
    }
    function reduceAllowance(address _who,uint _amount)  internal{
        emit AllowanceChanged(_who,msg.sender,allowance[_who],allowance[_who].sub(_amount));
        allowance[_who]=allowance[_who].sub(_amount);
    }
    
}