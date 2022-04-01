
pragma solidity ^0.8.1;
//pragma solidity ^0.5.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Allowance is Ownable{
    
   using SafeMath for uint;
   
   
    // this event is when we change the allowance 
    event AllowanceChange(address indexed forWho , address indexed fromWhom,uint oldAmt, uint newAmt);
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    mapping(address => uint) public allowance;
    
    function addAllowance(address who , uint amount) public onlyOwner{
        emit AllowanceChange(who, msg.sender,allowance[who] , amount);
        allowance[who] = amount;
    }
    
    modifier ownerRAllow(uint amount){
        require(isOwner() || allowance[msg.sender] >= amount , "You are not allowed");
        _;
    }
    
    // reducing the amount from the contract/ amount whenever it is whithdrwal
    function deductAllowance(address who, uint amount) internal ownerRAllow(amount){
        emit AllowanceChange(who,msg.sender, allowance[who],allowance[who].sub(amount));
        allowance[who] = allowance[who].sub(amount);
    }
    
    
}
