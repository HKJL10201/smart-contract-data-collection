//SPDX-License-Identifier: IIESTS
pragma solidity ^0.8.0;
import "./Allowance.sol";

// ----xxxxxxxxxx------ Step 1:-- simple Taking deposite to the SC though fallback function ---xxxxxxxxxxxxxxxxxxxx------

// contract simpleWallet{
//     function withdrawMoney(address payable _to,uint _amount) public {
//         _to.transfer(_amount);
//     }
//     function() external payable{}
// }

// ---------------------------------------------xxxxxxxxxxxxxxx------------------------------------------------------------


// -----xxxxxxxxxxxxxx----- Step 2:- (securing the Smart contract using require,modifier) ----xxxxxxxxxxxxxxxxxx-------

// contract simpleWallet{
//     address public owner;
//     constructor() public{
//         owner = msg.sender;
//     }
//     modifier onlyOwnerIsAllowed(){
//         require(owner == msg.sender,"You are not allowed");
//         _;
//     }
//     function withdrawMoney(address payable _to,uint _amount) public onlyOwnerIsAllowed{
//         _to.transfer(_amount);
//     }
//     function() external payable{}
// }

// --------------------------------------------------------------------------------------------------------------------

/* 
    Step 3:- Re-Using OpenZepline Smart Contracts;
    Step 4:- Add Allowance Functionality in Allowance.sol
    Step 5:- Add reduce-Allowance Functionality  in Allowance.sol
    Step 6:- Increasing Readabilty of code by dividing it into mutiple Smart Contracts & inheritance
    Step 7:- Adding Event - to emit logs in Allowance.sol as well as in simpleWallet.sol
    step 8:- Adding SafeMath Library in Allowance.sol
    step 9:- Renounce Ownership
 --------------------------- */


contract simpleWallet is Allowance{
    event moneySent(address indexed _to,uint _amount);
    event moneyReceived(address indexed _from,uint _amount);

    function withdrawMoney(address payable _to,uint _amount) public ownerOrAllowed(_amount){
        require(_amount<= address(this).balance,"Not enough Balance");
        if(!isOwner()){
            reduceAllowance(msg.sender,_amount);
        }
        emit moneySent(_to,_amount);
            _to.transfer(_amount);
    }

    function  renounceOwnership() public override onlyOwner{
        revert("Can't Renounce Ownership Here");
    }

    receive () external payable{
        emit moneyReceived(msg.sender,msg.value);
    }

}
