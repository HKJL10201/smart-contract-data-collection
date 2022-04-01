pragma solidity > 0.6.1 < 0.7.0; 
import "./Authenticator.sol";

contract Wallet is Authenticator{
    uint public balance;
    address public owner;
    
    constructor() public{
        owner = msg.sender;
    }
    
    
    function withdraw(uint amount) public {
        uint toTransfer = amount;
        amount = 0;
        balance -= toTransfer;
        msg.sender.transfer(toTransfer);
        toTransfer = 0;
        
    }
    
    function deposit() public payable {
        require( msg.value > 0 );
        balance += msg.value;
    }
    
    function transfer(address payable payee, uint amount, bytes32 encodedCode) public authenticator(encodedCode) {
        uint toTransfer = amount;
        amount = 0;
        balance -= toTransfer;
        payee.transfer(toTransfer);
        toTransfer = 0;
    }
    
    modifier authenticator(bytes32 encodedCode){
        require (compareCode(encodedCode) == true);
        _;
    }
    
}