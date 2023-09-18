//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
import "./Allowance.sol";

contract SharedWallet is Allowance {
    event MoneySent(address indexed _from, address indexed _beneficiary, uint amount);
    event MoneyReceived(address indexed _from, uint amount);
    
    /*
     *Used to withdraw amount from smart contarct and send it to the specified account
     */
    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Contract doesn't own enough money");
        if (!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        emit MoneySent(msg.sender, _to, _amount);
        _to.transfer(_amount);
    }
    
    /*
     *removing ownership for the smart contract is restricted by overriding the functionality in 
     *derived class
     */
    function renounceOwnership() public override onlyOwner {
        revert("Can't renounce ownership here");
    }

    /*
     *Fallback function which receives amount 
     */
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}