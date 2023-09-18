// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./ETH_Keycrypt.sol";

/**
 * A sample factory contract for ETH_Keycrypt
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract ETH_Factory {
    ETH_Keycrypt public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new ETH_Keycrypt(_entryPoint);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(address _owner, address _guardian1, address _guardian2, uint256 salt) public returns (ETH_Keycrypt ret) {
        address addr = getAddress(_owner, _guardian1, _guardian2, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return ETH_Keycrypt(payable(addr));
        }
        ret = ETH_Keycrypt(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(ETH_Keycrypt.initialize, (_owner, _guardian1, _guardian2))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(address _owner, address _guardian1, address _guardian2, uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(ETH_Keycrypt.initialize, (_owner, _guardian1, _guardian2))
                )
            )));
    }
}