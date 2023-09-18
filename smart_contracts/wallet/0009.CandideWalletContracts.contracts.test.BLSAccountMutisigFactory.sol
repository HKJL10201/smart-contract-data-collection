// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "./BLSAccountMultisig.sol";

/// @author eth-infinitism/account-abstraction - https://github.com/eth-infinitism/account-abstraction
/// @author modified by CandideWallet Team

/**
 * Based n SimpleAccountFactory
 * can't be a subclass, since both constructor and createAccount depend on the
 * actual wallet contract constructor and initializer
 */
contract BLSAccountMultisigFactory {
    BLSAccountMultisig public immutable accountImplementation;

    constructor(IEntryPoint entryPoint, address aggregator){
        accountImplementation = new BLSAccountMultisig(entryPoint, aggregator);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     * Also note that out BLSSignatureAggregator requires that the public-key is the last parameter
     */
    function createAccount(uint salt, uint256[4][] memory aPublicKeys, 
        uint256 aThreshold) public returns (BLSAccountMultisig) {
        address addr = getAddress(salt, aPublicKeys, aThreshold);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return BLSAccountMultisig(payable(addr));
        }
        return BLSAccountMultisig(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(BLSAccountMultisig.initialize, (aPublicKeys, aThreshold))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(uint salt, uint256[4][] memory aPublicKey, 
        uint256 aThreshold) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(BLSAccountMultisig.initialize, (aPublicKey, aThreshold))
                )
            )));
    }
}