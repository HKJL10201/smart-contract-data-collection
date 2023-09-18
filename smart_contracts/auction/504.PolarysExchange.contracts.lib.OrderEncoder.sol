// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order, Auction} from "./Structs.sol";

contract OrderEncoder {
    function _hashOrder(Order calldata order) public pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    function _hashKeys(
        address trader,
        address collection,
        uint256 tokenId,
        uint256 expirationTime
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    trader,
                    collection,
                    tokenId,
                    expirationTime
                )
            );
    }

    function _hashAuction(
        Auction calldata auction
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(auction));
    }
}
