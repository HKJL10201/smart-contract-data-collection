pragma solidity ^0.8.10;

// Basic Evmos Wallet
// Anyone can send PHOTON
// Only owner can withdraw
contract EvmosWallet {

    address payable public owner;
    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "The caller is not the owner of this contract");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}
