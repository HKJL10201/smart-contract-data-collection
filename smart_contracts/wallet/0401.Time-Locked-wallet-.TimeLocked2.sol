pragma solidity >=0.7.0 <0.9.0;

contract TimeLocked
{
    struct Payment {
        uint amount;
        uint lockedUntil;
    }
    mapping(address  => Payment) public account;
    
    //working fine but input value must be in wei
    function claim(uint _amount) public payable{
    require(_amount <= account[msg.sender].amount, "owner doesn't own enough money");
    require(account[msg.sender].lockedUntil < block.timestamp, "You cant winthdraw money right now, kidnly wait");
    account[msg.sender].amount -= _amount;
    address payable to = payable(msg.sender);
    to.transfer(_amount);
    }
    
    function deposit() public payable { 
       // Payment memory payment = Payment(msg.value, block.timestamp);
        account[msg.sender].amount += msg.value;
        account[msg.sender].lockedUntil=block.timestamp+ 1 minutes;
    }
    
}
