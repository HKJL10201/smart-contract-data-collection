//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// importing allowance/reduced allowance functionalities from allowance.sol 
import "./Allowance.sol";

contract smart_wallet is Allowance{  
// event trigger for received money
    event MoneyReceived(address _sender, uint _amount);
// event trigger for withdrawn money
    event MoneyWithdrawn(address _to, uint _amount);
// function to withdraw allowance
    function WithdrawMoney(address payable _to, uint _amount) public Owner_or_Allowed(_amount){
        // to check for enough funds in contract
        require(_amount <= address(this).balance, "Contract does not have enough Balance");
        _to.transfer(_amount);
        // reduces allowance of the recipent
        if(!(msg.sender == owner())){
            ReduceAllowance(_to, _amount);
        }
        
        emit MoneyWithdrawn(_to, _amount);

    }
    //function to receive money
    receive () external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}