// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface ITicketSpender {
    function verifyTicketSpending(
        uint256 option, uint256 serial, uint256 root,
        bytes memory proof
    ) external view returns (bool);
}