// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract Proxiable {
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7; // keccak256("PROXIABLE")
    }

    function updateCodeAddress(address newAddress) internal {
        (bool success, bytes memory result) = newAddress.call(abi.encodeWithSignature("proxiableUUID()"));
        require(success && abi.decode(result, (bytes32)) == proxiableUUID(), "not proxiable");
        // store implementation on slot keccak256("PROXIABLE")
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
}
