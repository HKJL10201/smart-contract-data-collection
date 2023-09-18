//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Allowance is Ownable{
    event AllowanceChanged (address indexed _forWho, address indexed _byWhom, uint OldAmount, uint _newAmount);
    mapping (address=>uint) allowance;

    modifier OwnerOrAllowed(uint _amount) {

        require(isOwner() || allowance[msg.sender]>=_amount,'you are not allowed ');
        _;
    }
    modifier amountCheck(uint _amount){
        require(_amount<= address(this).balance,'Not ewnough money in smart contrat');

        _;
    } 

    function isOwner() internal view returns(bool){
        return owner()==msg.sender;
        
    }
    function renounceOwnership() public override virtual onlyOwner {  // override for kicking out the function that was in the file we imported
        revert('No option ins this smart contract !');
    }
    function allowanceSet(address _who,uint _limit) public onlyOwner {
        emit AllowanceChanged(_who, msg.sender, allowance[_who], _limit);
        allowance[_who] = _limit;
    }
    function reduceAllowance(address _whom,uint _amount)  internal {
        emit AllowanceChanged(_whom, msg.sender, allowance[_whom], allowance[_whom]-=_amount);
        allowance[_whom]-=_amount;
    }
}