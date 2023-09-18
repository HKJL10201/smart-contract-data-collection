TOKEN W/CHAINBRIDGE CROSS CHAIN TOKEN AND RING signature
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../chainbridge-solidity/contracts/interfaces/IBridge.sol";


contract PlaySwapToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    uint256 private constant _maxSupply = 500_000_000 * (10 ** 18);

    bytes4 private constant RING_SIGNATURE_VERIFIER = bytes4(keccak256("verifyRingSignature(bytes32,bytes32[],bytes32[],uint8[],bytes32[],bytes32[])"));

    IBridge public bridge;

    constructor(address owner, address _bridge) ERC20("PlaySwap Token", "DEX") {
        _mint(owner, _maxSupply);
        bridge = IBridge(_bridge);
    }

    function transfer(address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(_verifyRingSignature(_msgSender(), recipient, amount), "Invalid ring signature");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override nonReentrant returns (bool) {
        require(_verifyRingSignature(sender, recipient, amount), "Invalid ring signature");
        return super.transferFrom(sender, recipient, amount);
    }

    function deposit(uint8 destinationChainID, bytes32 resourceID, uint256 amount) external nonReentrant {
        _burn(_msgSender(), amount);
        bridge.deposit(destinationChainID, resourceID, abi.encodePacked(_msgSender(), amount));
    }

    function executeProposal(uint8 sourceChainID, uint64 depositNonce, address recipient, uint256 amount) external onlyOwner {
        bridge.executeProposal(sourceChainID, depositNonce, abi.encodePacked(recipient, amount));
    }

    function _verifyRingSignature(address sender, address recipient, uint256 amount) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, recipient, amount));
        bytes32[] memory image = new bytes32[](1);
        bytes32[] memory scalars = new bytes32[](1);
        uint8[] memory indexes = new uint8[](1);
        bytes32[] memory ephemeralKeys = new bytes32[](1);
        bytes32[] memory ringKeys = new bytes32[](1);

        image[0] = 0x0;
        scalars[0] = 0x0;
        indexes[0] = 0;
        ephemeralKeys[0] = 0x0;
        ringKeys[0] = 0x0;

        (bool success, bytes memory result) = address(0x0000000000000000000000000000000000000008).staticcall(
            abi.encodeWithSelector(RING_SIGNATURE_VERIFIER, hash, image, scalars, indexes, ephemeralKeys, ringKeys)
        );

        return success && abi.decode(result, (bool));
    }
}

/*
This updated PlaySwapToken contract integrates the ChainBridge contract to enable calling the bridge contract functions directly. Here's a summary of the changes:

1. Import the `IBridge` interface from the ChainBridge contracts.
2. Add a public variable `bridge` of type `IBridge` to store the bridge contract instance.
3. Update the constructor to accept an additional parameter `_bridge` of type `address` and set the `bridge` variable to the provided address.
4. Add a new function `deposit` that allows users to deposit tokens to the bridge. It takes three parameters: `destinationChainID`, `resourceID`, and `amount`. The function burns the tokens from the sender's balance and calls the `deposit` function of the bridge contract.
5. Add a new function `executeProposal` that allows the contract owner to execute a proposal on the bridge. It takes four parameters: `sourceChainID`, `depositNonce`, `recipient`, and `amount`. The function calls the `executeProposal` function of the bridge contract.

Note: Make sure to replace the ChainBridge import path with the correct path to the ChainBridge contracts in your project.
*/
