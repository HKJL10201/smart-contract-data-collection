// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.4 <0.9.0;

import "./ERC20Interface.sol";

contract Forwarder {
    // Address to which any funds sent to this contract will be forwarded
    address public parentAddress;

    event ForwarderDeposited(address from, uint value);
    event TokensCollected(address forwarderAddress, uint value, address tokenContractAddress);

    /**
     * Create the contract, and sets the destination address to that of the creator
     */
    constructor() {
        parentAddress = msg.sender;
    }

    /**
     * Modifier that will execute internal code block only if the sender is the parent address
     */
    modifier RequireParent {
        require(msg.sender == parentAddress, "Forwarder: caller is not the main wallet");
        _;
    }

    /**
     * Default function; Gets called when Ether is deposited, and forwards it to the parent address
     */
    receive() external payable {
        require(msg.value > 0, "Forwarder: Zero value transfer ?");
        // throws on failure
        payable(parentAddress).transfer(msg.value);
        // Fire off the deposited event if we can forward it
        emit ForwarderDeposited(msg.sender, msg.value);
    }

    function changeParent(address newParentAddress) public RequireParent {
        parentAddress = newParentAddress;
    }

    /**
     * Execute a token transfer of the full balance from the forwarder token to the parent address.
     * Since there's no right way to ensure tokenContractAddress is a token address, we secure this
     * function with RequireParent modifier.
     * @param tokenContractAddress the address of the erc20 token contract
   */
    function collectTokens(address tokenContractAddress) public RequireParent {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        uint256 forwarderBalance = instance.balanceOf(address(this));
        require(forwarderBalance > 0, "Forwarder: Empty token balance !");

        bool status = instance.transfer(parentAddress, forwarderBalance);
        require(status, "Forwarder: Error transferring to main wallet");

        // fire of an event just for the record!
        emit TokensCollected(address(this), forwarderBalance, tokenContractAddress);
    }

    /**
     * It is possible that funds were sent to this address before the contract was deployed.
     * We can collect those funds to the parent address.
     */
    function collect() public {
        uint256 value = address(this).balance;
        require(value > 0, "Forwarder: Empty balance !");

        // throws on failure
        payable(parentAddress).transfer(value);
    }
}
