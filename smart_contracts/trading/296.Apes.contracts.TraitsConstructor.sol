// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract TraitsConstructor is ERC1155Holder, ReentrancyGuard, Ownable {
    using Strings for uint256;

    IApes public apesContract;
    ITraits public traitsContract;
    address public secret;

    event Equipped(uint256 tokenId, string changeCode, address operator);

    constructor(
        address _apes,
        address _traits,
        address _secret
    ) {
        apesContract = IApes(_apes);
        traitsContract = ITraits(_traits);
        secret = _secret;
    }

    function equip(
        uint256 tokenId, // Ape id to be modified
        uint256[] memory traitsIn, // id of traits to be added
        uint256[] memory traitsOut, // id of traits to be removed
        uint256[] memory traitsOGOut, // id of original traits to be removed (need to be minted)
        string memory changeCode, // internal code to process image change
        bytes memory signature
    ) external nonReentrant {
        string memory traitCode; // Used to avoid unauthorized changes

        uint256[] memory InAmounts = new uint256[](traitsIn.length); // create arrays with amount 1 for safeBatchTransfer

        for (uint256 i = 0; i < traitsIn.length; i++) {
            InAmounts[i] = 1;

            traitCode = string.concat(traitCode, "I", traitsIn[i].toString()); // loop through traits to create traitCode
        }
        uint256[] memory OutAmounts = new uint256[](traitsOut.length); // create arrays with amount 1 for safeBatchTransfer

        for (uint256 i = 0; i < traitsOut.length; i++) {
            OutAmounts[i] = 1;

            traitCode = string.concat(traitCode, "O", traitsOut[i].toString()); // loop through traits to create traitCode
        }

        uint256[] memory OGOutAmouts = new uint256[](traitsOGOut.length); // create arrays with amount 1 for safeBatchTransfer

        for (uint256 i = 0; i < traitsOGOut.length; i++) {
            OGOutAmouts[i] = 1;

            traitCode = string.concat(
                traitCode,
                "OG",
                traitsOGOut[i].toString()
            ); // loop through traits to create traitCode
        }

        address tokenOwner = apesContract.ownerOf(tokenId); // Current owner of the Ape, allows SafeClaim equip/de-equip

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        tokenId,
                        traitCode,
                        changeCode,
                        msg.sender,
                        tokenOwner
                    )
                ),
                signature
            ), // Checks validity of back-end provided signatre
            "Equip: Signature is invalid"
        );

        if (traitsIn.length > 0) {
            traitsContract.safeBatchTransferFrom(
                msg.sender,
                address(this),
                traitsIn,
                InAmounts,
                ""
            ); // batch transfer traits in, from user to this contract
        }

        if (traitsOut.length > 0) {
            traitsContract.safeBatchTransferFrom(
                address(this),
                msg.sender,
                traitsOut,
                OutAmounts,
                ""
            ); // batch transfer traits in, from this contract to user
        }

        if (traitsOGOut.length > 0) {
            traitsContract.mintBatch(msg.sender, traitsOGOut, OGOutAmouts); // batch mint original traits, from traits contract to user
        }

        apesContract.confirmChange(tokenId); // Confirm the change on Apes contract (burn - mint)

        emit Equipped(tokenId + 10000, changeCode, msg.sender); // event emitted with new ID after burn - mint
    }

    function setContracts(address _apes, address _traits) external onlyOwner {
        apesContract = IApes(_apes);
        traitsContract = ITraits(_traits);
    }

    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}
