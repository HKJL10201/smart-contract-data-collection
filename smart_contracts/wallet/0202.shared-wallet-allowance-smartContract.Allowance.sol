pragma solidity ^0.8.1;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allowance is Ownable{
    
    event AllowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount, uint _newAmount);
    
    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
    
    mapping (address => uint) public allowance;
   
   function addAllowance(address _who, uint _amount) public onlyOwner{
       emit AllowanceChanged(_who,msg.sender,allowance[_who],_amount);
       allowance[_who]=_amount;
   }
    modifier ownerOrAllowed(uint _amount){
        require(isOwner() || allowance[msg.sender]>= _amount,"You are not allowed");
        _;
    }
    function reduceAllowance(address _who,uint _amount) internal {
         emit AllowanceChanged(_who, msg.sender, allowance[_who], allowance[_who] - _amount);
        allowance[_who]-=_amount;
    }
}
