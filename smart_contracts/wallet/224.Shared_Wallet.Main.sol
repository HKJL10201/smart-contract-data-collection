pragma solidity ^0.8.4;

import "./UserChecks.sol";

// Shared_Wallet Smart Contract containing the following functionalities
// - Send Money to The smart contract
// - Withdraw Money from the smart contract
//      - Totality of the money locked - Owner Restricted
//      - Allowance Based - Generic UserChecks
// - Set Allowance - Owner Restricted
// - Set Frequency Allowance - Owner Restricted
contract Shared_Wallet is UserChecks {

     event MoneySent(address indexed _beneficiary, uint amount);
     event MoneyWithdrawn(address indexed _beneficiary, uint amount);

    //Function to send money to the smart contract
     function sendMoney() public payable {
         balanceReceived [msg.sender] += msg.value;
         emit MoneySent(msg.sender,msg.value);
     }

     //Function to set the maximum allowance that a normal user is allowed to withdraw - Owner Only
     function setAllowance(uint _allowance) public payable {
         require(msg.sender == owner, "You are not the owner and cannot change the allowance value");
         require(_allowance >= 0, "The allowance set must be positive");
         uint Old_Allowance = allowance;
         allowance = _allowance;
         emit AllowanceChanged(Old_Allowance,_allowance);
     }
     //Function to set how often the allowance can be withdrawn - Owner Only
     function setfrequencyWithdrawal(uint _allowance_frequency) public {
        require(msg.sender == owner, "You are not the owner and cannot change the allowance value");
        require(_allowance_frequency >= 0, "The allowance set must be positive");
         uint Old_Freq_Allowance = allowance_frequency;
         allowance_frequency = _allowance_frequency;
         emit FrequencyAllowanceChanged(Old_Freq_Allowance,_allowance_frequency);
    }

     //Function to withdraw the totality of the money locked in the smart contract - Owner Only
     function withdrawTotalMoney(address payable _to) public {
         require(msg.sender == owner, "You are not the owner and cannot withdraw all the funds contained in the smart contract");
         _to.transfer(getBalance());
          emit MoneyWithdrawn(msg.sender,address(this).balance);
     }
     
     //Function to withdraw a smaller amount of money than the maximum available
     // - Owner - Can withdraw as much as desired
     // - User - Can withdraw an amount <= than the allowance
     function withdrawPartialMoney(address payable _to, uint _amount) public payable {
         require(_amount <= getAllowance(), "You cannot withdraw more than your allowance");
         require(_amount <= getBalance(), "There are not enough funds Locked in the Smart Contract");
         if (msg.sender == owner){
            _to.transfer(_amount);
            emit MoneyWithdrawn(msg.sender,_amount);
         } else {
             if (TimeCount[msg.sender] < block.timestamp) {
                 countAmountWithdrawn[msg.sender] = 0;
                 TimeCount[msg.sender] = 0;
                 }
             if (countAmountWithdrawn[msg.sender] == 0) {
                 TimeCount[msg.sender] = block.timestamp + allowance_frequency;
                 }
             countAmountWithdrawn[msg.sender] = countAmountWithdrawn[msg.sender] + _amount;
             require(countAmountWithdrawn[msg.sender] <= getAllowance(), "You are not allowed to withdraw more than your allowance");
             _to.transfer(_amount);
             emit MoneyWithdrawn(msg.sender,_amount);
             }
     }

     //Function to destroy the smart contract - Owner Only
    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    } 
}