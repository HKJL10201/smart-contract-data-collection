// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BundlerV3 {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function onERC721Received(
        address /*_operator*/,
        address /* _from */,
        uint256 /* _tokenId */,
        bytes calldata /* _data */
    ) external pure returns (bytes4) { return 0x150b7a02; }

    function onERC1155Received(
        address /* _operator */,
        address /* _from */,
        uint256 /* _id */,
        uint256 /* _value */,
        bytes calldata /* _data */
    ) external pure returns (bytes4) { return 0xf23a6e61; }

    function onERC1155BatchReceived(
        address /* _operator */,
        address /* _from */,
        uint256[] calldata /* _ids */,
        uint256[] calldata /* _values */,
        bytes calldata /* _data */
    ) external pure returns (bytes4) { return 0xbc197c81; }

    fallback() external payable {
        require(msg.sender == owner);
        assembly {
            let end := calldatasize()
            for { let p := 0 } lt(p, end) { p := add(p, 0x20) } {
                let encodedHeader := calldataload(p)
                let target := shr(96, encodedHeader)
                let sendValue := shr(176, shl(160, encodedHeader))
                let size := and(encodedHeader, 0xffff)

                if iszero(iszero(size)) {
                    calldatacopy(0, add(p, 0x20), size)
                    p := add(p, size)
                }

                if iszero(call(gas(), target, sendValue, 0, size, 0, 0)) {
                    revert(0, 0)
                }
            }
        }
    }
}