// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "openzeppelin/utils/Create2.sol";

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import "./Proxy/UUPSProxy.sol";
import "./MyWallet.sol";

/**
 * A factory contract for MyWallet
 * Modified from https://github.com/eth-infinitism/account-abstraction/blob/develop/contracts/samples/SimpleAccountFactory.sol
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract MyWalletFactory {
    MyWallet public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new MyWallet(_entryPoint);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        address[] memory _owners,
        uint256 _leastConfirmThreshold,
        bytes32[] memory _guardianHashes,
        uint256 _recoverThreshold,
        address[] memory _whiteList,
        uint256 salt
    ) public returns (MyWallet ret) {
        address addr = getAddress(_owners, _leastConfirmThreshold, _guardianHashes, _recoverThreshold, _whiteList, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return MyWallet(payable(addr));
        }
        ret = MyWallet(payable(new UUPSProxy{salt : bytes32(salt)}(
                abi.encodeCall(
                    MyWallet.initialize,
                    (_owners, _leastConfirmThreshold, _guardianHashes, _recoverThreshold, _whiteList)
                ),
                address(accountImplementation)
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        address[] memory _owners,
        uint256 _leastConfirmThreshold,
        bytes32[] memory _guardianHashes,
        uint256 _recoverThreshold,
        address[] memory _whiteList,
        uint256 salt
    ) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(UUPSProxy).creationCode,
                abi.encode(
                    abi.encodeCall(
                        MyWallet.initialize,
                        (_owners, _leastConfirmThreshold, _guardianHashes, _recoverThreshold, _whiteList)
                    ),
                    address(accountImplementation)
                )
            )));
    }
}