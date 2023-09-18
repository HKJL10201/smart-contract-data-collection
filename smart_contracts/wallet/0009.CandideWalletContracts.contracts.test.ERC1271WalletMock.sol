// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ERC1271WalletMock is Ownable, IERC1271 {
    constructor(address originalOwner) {
        transferOwnership(originalOwner);
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4 magicValue) {
        return ECDSA.recover(hash, signature) == owner() ? this.isValidSignature.selector : bytes4(0);
    }
}

contract ERC1271MaliciousMock is IERC1271 {
    function isValidSignature(bytes32, bytes memory) public pure override returns (bytes4) {
        assembly {
            mstore(0, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            return(0, 32)
        }
    }
}
