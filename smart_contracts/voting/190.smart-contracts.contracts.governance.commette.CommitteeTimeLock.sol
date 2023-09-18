// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CommitteeTimeLock is TimelockController {
    // minDelay is how long you have to wait before executing
    // proposers is the list of addresses that can propose
    // executors is the list of addresses that can execute
    //`admin`: optional account to be granted admin role; disable with zero address  /**
    /**
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */

    event CommitteeTokenReceived(uint, address);

    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}

    // When using the safeTransferFrom function to send ERC721 tokens to a contract address,
    // it will fail unless the receiving contract properly implements the ERC721TokenReceiver interface.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        emit CommitteeTokenReceived(tokenId, from);
        return this.onERC721Received.selector;
    }
}
