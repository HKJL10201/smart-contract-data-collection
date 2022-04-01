pragma solidity ^0.8.4;

contract SharedWallet {
    
    address owner;
    uint totalBalance;
    mapping(address => uint) allowance;
    
    constructor() {
        owner = msg.sender;
    }
    
    function sendFunds () payable public {
        require(msg.sender == owner, "Not Owner");
        allowance[owner] += msg.value;
        totalBalance += msg.value;
    }
    
    function getTotalBalance () public view returns(uint) {
        return totalBalance;
    }
    
    function setAllowance (address _address, uint _amount) public {
        require(msg.sender == owner, "Not Owner");
        allowance[_address] = _amount;
    }
    
    function spendAllowance (address payable _to, uint _amount) payable public {
        require(_amount <= totalBalance, "Not enough funds in account");
        require(_amount <= allowance[msg.sender], "Amount exceeds remaining allowance");
        allowance[msg.sender] -= _amount;
        totalBalance -= _amount;
        _to.transfer(_amount);
    }
    
    function getRemainingAllowance (address _address) public view returns(uint) {
        return allowance[_address];
    }
}