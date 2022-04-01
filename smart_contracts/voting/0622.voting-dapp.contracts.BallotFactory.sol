// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ballot.sol";

contract BallotFactory {
    address[] public deployedBallots;

    function createBallot(
        string memory _ballotOfficialName,
        string memory _proposal
    ) public {
        address newBallotAddr = address(
            new Ballot(msg.sender, _ballotOfficialName, _proposal)
        );
        deployedBallots.push(newBallotAddr);
    }

    function getDeployedBallot() public view returns (address[] memory) {
        return deployedBallots;
    }
}
