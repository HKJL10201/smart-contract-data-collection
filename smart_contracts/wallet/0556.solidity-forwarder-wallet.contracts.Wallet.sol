// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.4 <0.9.0;

import "./Forwarder.sol";
import "./ERC20Interface.sol";

contract Wallet {
    // Public fields
    address public ownerAddress;

    // Events
    event Deposited(address from, uint value);
    event ForwarderCreated(address forwarderAddress);
    event Transacted(
        address msgSender, // Address of the sender of the message initiating the transaction
        address toAddress, // The address the transaction was sent to
        uint value // Amount of Wei sent to the address
    );
    event TransactedToken(
        address msgSender, // Address of the sender of the message initiating the transaction
        address toAddress, // The address the transaction was sent to
        uint value, // Amount of Wei sent to the address
        address tokenContractAddress // The token's address
    );

    /**
    * Create the contract, and sets the owner address to that of the creator
    */
    constructor() {
        ownerAddress = msg.sender;
    }

    /**
     * Modifier that will execute internal code block only if the sender is the parent address
     */
    modifier RequireOwner {
        require(msg.sender == ownerAddress, "Main wallet: caller is not the owner");
        _;
    }

    /**
    * Gets called when a transaction is received without calling a method
    */
    receive() external payable {
        require(msg.value > 0, "Main wallet: Zero value transfer ?");
        emit Deposited(msg.sender, msg.value);
    }

    /**
    * Create a new contract (and also address) that forwards funds to this contract
    */
    function createForwarder() external {
        Forwarder f = new Forwarder();
        emit ForwarderCreated(address(f));
    }

    /**
    * Create a bunch of forwarders
    */
    function createForwarders(uint _count) external {
        for (uint i = 0; i < _count; i++) {
            Forwarder f = new Forwarder();
            emit ForwarderCreated(address(f));
        }
    }

    /**
    * Change the parent wallet to which all the funds are transferred, this function is very sensitive and could be a security risk
    *
    * @param forwarderAddress the address of the forwarder address we want to change the parent of
    * @param newParentAddress address of a new walletsimple contract to which all the incoming funds will be sent to from now on.
    */
    function changeForwarderParent(
        address forwarderAddress,
        address newParentAddress
    ) external RequireOwner {
        Forwarder forwarder = Forwarder(payable(forwarderAddress));
        forwarder.changeParent(payable(newParentAddress));
    }

    /**
    * Execute a token collection from one of the forwarder addresses.
    *
    * @param forwarderAddress the address of the forwarder address to collect the tokens from
    * @param tokenContractAddress the address of the erc20 token contract
    */
    function collectForwarderTokens(
        address forwarderAddress,
        address tokenContractAddress
    ) external RequireOwner {
        Forwarder forwarder = Forwarder(payable(forwarderAddress));
        forwarder.collectTokens(tokenContractAddress);
    }

    /**
    * Send native currency amount from this Wallet contract
    *
    * @param toAddress the destination address to send an outgoing transaction
    * @param value the amount in Wei to be sent
    */
    function send(
        address toAddress,
        uint value
    ) external RequireOwner {
        require(address(this).balance >= value, "Main wallet: No balance available for this transaction !");
        payable(toAddress).transfer(value);
        emit Transacted(msg.sender, toAddress, value);
    }


    /**
    * Send amount in tokens from this Wallet contract
    *
    * @param toAddress the destination address to send an outgoing transaction
    * @param value the amount in tokens to be sent
    * @param tokenContractAddress the address of the erc20 token contract
    */
    function sendToken(
        address toAddress,
        uint value,
        address tokenContractAddress
    ) external RequireOwner {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint256 _balance = instance.balanceOf(address(this));
        require(_balance > 0, "Main wallet: Empty token balance !");

        bool status = instance.transfer(toAddress, value);
        require(status, "Main wallet: Error transferring to main wallet");
        emit TransactedToken(msg.sender, toAddress, value, tokenContractAddress);
    }
}