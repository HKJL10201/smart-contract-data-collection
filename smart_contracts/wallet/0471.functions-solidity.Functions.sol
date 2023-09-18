pragma solidity ^0.5.13;

contract FunctionsExample {
    
    mapping(address => uint) public accounts;
    address payable owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function sendMoney() payable public {
        require(msg.value > 0, "The amount to send must be greater than 0!");
        assert(accounts[msg.sender] + msg.value > accounts[msg.sender]);
        
        accounts[msg.sender] += msg.value;
    }
    
    function withdrawMoney(address payable toAccount, uint amount) public {
        require(accounts[msg.sender] > accounts[msg.sender] - amount, "Not enough Ether to make this transfer.");
        accounts[msg.sender] -= amount;
        toAccount.transfer(amount);
    }
    
    function convertToEth(uint weiAmount) public pure returns (uint){
        return weiAmount / 1 ether;
    }
    
    function getOwner() public view returns(address){
        return owner;
    }
    
    function destroyContract() public {
        require(msg.sender == owner, "Only the owner can destroy the contract.");
        selfdestruct(owner);
    }
    
    function () external payable {
        sendMoney();
    }
    
}