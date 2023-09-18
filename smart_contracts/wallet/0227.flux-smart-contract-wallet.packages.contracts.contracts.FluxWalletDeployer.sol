// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./FluxWallet.sol";

contract FluxWalletDeployer {
    function deployWallet(
        IEntryPoint entryPoint,
        address owner,
        uint256 root,
        uint256 salt
    ) public returns (FluxWallet) {
        return new FluxWallet{salt: bytes32(salt)}(entryPoint, owner, root);
    }
}
