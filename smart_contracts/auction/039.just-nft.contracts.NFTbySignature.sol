// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./NFT.sol";

contract NFTbySignature is NFT {
    mapping(uint256 => bool) private _nonces;

    constructor(
        string memory name,
        string memory symbol,
        address auction,
        address projectTreasury
    ) NFT(name, symbol, auction, projectTreasury) {} // solhint-disable-line no-empty-blocks

    function mintNFTbySignature(
        address author,
        string memory nftURI,
        bytes32 hash,
        uint256 royaltyValue,
        bool setApprove,
        uint256 nonce,
        bytes memory signature
    ) external returns (uint256) {
        require(!_nonces[nonce], "Invalid Nonce");
        _nonces[nonce] = true;

        bytes32 messageHash = keccak256(
            abi.encode(
                author,
                nftURI,
                hash,
                royaltyValue,
                setApprove,
                nonce,
                this,
                block.chainid
            )
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        address miningSigner = ecrecover(ethSignedMessageHash, v, r, s);
        require(hasRole(MINTER_ROLE, miningSigner), "Invalid Signature");

        return mint(author, nftURI, hash, royaltyValue, setApprove);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "Invalid Signature length");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
