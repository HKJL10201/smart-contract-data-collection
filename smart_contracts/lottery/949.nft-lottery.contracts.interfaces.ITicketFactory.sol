// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITicketFactory {
    function beacon() external view returns (address);

    function ticketRegistry(address ticket) external view returns (bool);

    function createTicket(
        uint256 startBlock,
        uint256 endBlock,
        uint256 ticketPrice,
        string memory name,
        string memory symbol,
        string memory uri,
        bytes32 _salt
    ) external;

    function preComputeAddress(address _creator, bytes32 _salt)
        external
        view
        returns (address predicted);
}
