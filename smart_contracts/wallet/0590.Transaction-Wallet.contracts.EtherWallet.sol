pragma solidity >=0.4.17 <0.7.0;

contract EtherWallet {
    address public owner;
    
    constructor(address _owner) public {
        owner = _owner;
    }
    
    function deposit() payable public {
        
    }
    
    function sendEther(address payable _receipt, uint _amount) public {
       if(msg.sender == owner) {
        _receipt.transfer(_amount);
        return;
       }
       revert("Sender is not allowed to perform this transaction");
    }
    
    function etherBalance() view public returns(uint) {
        return address(this).balance;
    }
}