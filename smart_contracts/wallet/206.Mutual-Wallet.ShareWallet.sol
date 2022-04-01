pragma solidity ^0.8.1;
//pragma solidity ^0.5.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


import "abc.sol";



contract walletshared is Allowance{
    
    // money sent to the address
    event MoneySentTo(address indexed beneficiaryAdd , uint amount);
    // money receive by the address
    event MoneyReceivd(address indexed fromTheAdd , uint amount);
    
    function moneywithdraw(address payable _toperson , uint amount) public ownerRAllow(amount){
        require(amount <= address(this).balance, "SORRY Not Enough Funds available !!!!");
        
        if(!isOwner()){
            deductAllowance(msg.sender,amount);
        }
        
        // money sent to the _toperson
        emit MoneySentTo(_toperson,amount);
        
        _toperson.transfer(amount);
    }
    
    
    function removeRenounceOwnership() public onlyOwner {
        // we are just override the reounceOwnership , as other owner cannot do that
        revert ("This option is not available for you !!!");
    }
    
    
    receive () external payable {
        // receive money
        emit MoneyReceivd(msg.sender,msg.value);
    }
    
}
//SPDX-License-Identifier: MIT