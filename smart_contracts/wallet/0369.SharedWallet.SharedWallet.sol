
//SPDX-License-Identifier: MIT

    pragma solidity 0.8.12;

    import "./Allowance.sol";

    contract SharedWallet is Allowance {

        event SendMoney(address indexed _beneficiery, uint _amount);
        event ReceivedMoney(address indexed _form, uint _amount);

    function WithdrawMoney (address payable _to, uint _amount) ownerOrAllowed (_amount) public {
       require (_amount <= address(this).balance, "there are not enough founds");
       if(!(owner() == msg.sender)){
           reduceAllowance(msg.sender, _amount);
       }
        emit SendMoney(_to, _amount);
        _to.transfer(_amount);
    }
    receive () external payable {
        emit ReceivedMoney(msg.sender, msg.value);
    }
    function renounceOwnership() public pure override {
        revert ("can't renaunce ownership in this smartcontract");
    }
    }