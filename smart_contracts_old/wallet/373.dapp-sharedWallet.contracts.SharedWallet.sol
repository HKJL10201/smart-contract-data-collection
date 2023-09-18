pragma solidity 0.8.4;

import './Allowance.sol';

contract SharedWallet is Allowance {

    event BalanceChanged(uint balance);

    function getBalance() public onlyOwner view returns(uint)  {
        return address(this).balance;
    }
    
    function withdrawMoney(address payable to, uint amount) public onlyOwnerOrAllowed(amount) {
        require(address(this).balance >= amount, 'You do not have enough funds');
        if (!isOwner()) {
            reduceAllowance(amount);
        }
        to.transfer(amount);
        emit BalanceChanged(address(this).balance);
    }
    
    receive() external payable {
        
    }
    
 
}