pragma solidity ^0.5.13;

contract SharedWallet {
    
    address payable public owner;
    mapping(address => uint) public wallet;
    
    event walletToppedUp(address indexed to, address indexed from, uint amount);
    event walletWithdrawn(address indexed account, uint amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier isOwner {
        require (msg.sender == owner, "This operation is reserved to the wallet owner!");
        _;
    }
    
    function topUp() public payable {
        assert(wallet[msg.sender] + msg.value > wallet[msg.sender]);
        wallet[msg.sender] += msg.value;
        
        emit walletToppedUp(msg.sender, msg.sender, msg.value);
    }
    
    function topUpWallet(address payable toAddress) public payable isOwner {
        assert(wallet[toAddress] + msg.value > wallet[toAddress]);
        wallet[toAddress] += msg.value;
        
        emit walletToppedUp(toAddress, msg.sender, msg.value);
    }
    
    function withdraw(uint amount) public {
        assert(wallet[msg.sender] - amount < wallet[msg.sender]);
        assert(wallet[msg.sender] - amount >= 0);
        
        wallet[msg.sender] -= amount;
        address(msg.sender).transfer(amount);
        
        emit walletWithdrawn(msg.sender, amount);
    }
    
    function withdrawFromWallet(address fromAddress, uint amount) public isOwner {
        assert(wallet[fromAddress] - amount < wallet[fromAddress]);
        assert(wallet[fromAddress] - amount >= 0);
        
        wallet[fromAddress] -= amount;
        owner.transfer(amount);
        
        emit walletWithdrawn(fromAddress, amount);
    }

    //fallback function
    function () external payable {
        topUp();
    }
    
    function terminateWallet() public isOwner {
        selfdestruct(owner);
    }
    
}