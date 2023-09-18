pragma solidity >=0.4.21 <0.7.0;

contract scooterTransactions {
    
    uint public totalBalance;
    address payable owner;
    
    // Stores the address of the person who deployed
    // the contract
    constructor() public {
        owner = msg.sender;
    }
    
    // Destroys the contract and sends all the funds
    // to the owner
    function destroyContract() public {
        require(msg.sender == owner, 'Only the owner can destroy the smart contract!');
        selfdestruct(owner);
    }
    
    // Makes a payment to the smart contract
    function makePayment() public payable {
        assert(totalBalance + msg.value >= totalBalance);
        totalBalance += msg.value;
    }
    
    // Sends all the payments to the owner
    function withdrawPayments() public {
        require(msg.sender == owner, 'Only the owner can withdraw payments!');
        owner.transfer(totalBalance);
        totalBalance = 0;
    }
}