// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "./PlonkVerifier.sol";
import "../interfaces/ITicketSpender.sol";

contract TicketSpender is ITicketSpender, PlonkVerifier {

    function verifyTicketSpending(
        uint256 option, uint256 serial, uint256 root,
        bytes memory proof
    ) public view override returns (bool ret) {
        uint256[] memory pubSignals = new uint256[](3);
        pubSignals[0] = option;
        pubSignals[1] = serial;
        pubSignals[2] = root;
        ret = verifyProof(proof, pubSignals);
    }
}