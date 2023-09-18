// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.1;

contract SimpleWallet {
    
    // Total balance deposited into dApp
    uint public BalanceReceived;
    
    // Deposit Ether into dApp
    function Deposit() public payable {
        BalanceReceived += msg.value;
    }
    // Current dApp balance
    function AppBalance() public view returns(uint) {
        return address(this).balance;
    }
    // Check wallet balance
    function MyBalance() public view returns(uint) {
        return msg.sender.balance;
    }
    
    // Withdraw from dApp
    function Withdraw() public {
        address payable to = payable(msg.sender);
        to.transfer(AppBalance());
    }
    
    //Send money from dApp to other address
    function Send(address payable _to) public {
        _to.transfer(AppBalance());
    }
}
