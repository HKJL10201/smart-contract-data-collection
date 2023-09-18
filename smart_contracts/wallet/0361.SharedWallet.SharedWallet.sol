pragma solidity ^0.6.0;

import "./Allowance.sol";

contract SharedWallet is Allowance {
    using SafeMath for uint256;
    
    event Deposit(address indexed _from, uint256 _amount);
    event Withdrawal(uint256 _amount, address indexed _from, address indexed _to);
   
    receive() external payable {
        balance.totalBalance = balance.totalBalance.add(msg.value);

        emit Deposit(msg.sender, msg.value);
    }
    
    fallback() external {
    }
    
    function withdraw(address payable _to, uint256 _amount) public onlyOwnerOrAllowed(_amount) {
        require(balance.totalBalance >= _amount, "Not enough funds");
        
        allowances[msg.sender] = allowances[msg.sender].sub(_amount);
               
        Payment memory payment = Payment(msg.sender, _to, _amount, block.timestamp);
        
        balance.totalBalance = balance.totalBalance.sub(_amount);
        balance.payments[balance.numPayments] = payment;
        balance.numPayments++;
        
        
        _to.transfer(_amount);
        
        emit Withdrawal(_amount, msg.sender, _to);
    }
}