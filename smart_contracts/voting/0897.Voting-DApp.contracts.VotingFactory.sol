// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./Voting.sol";

/// @author Jeff Soriano
/// @title A factory that generates Voting contracts
contract VotingFactory {
    address[] public votingContracts;

    /// Creates a Voting contract
    /// @param manager the address that will be managing the Voting contract
    /// @param description the description of the Voting contract that tells the voters what they're voting for
    /// @param optionADescription the description of optionA
    /// @param optionBDescription the description of optionB
    /// @param intendedVotingDate the intended date that the manager will move the contract to the Voting phase, in Unix time
    /// @param intendedClosingDate the intended date that the manager will move the contract to the Closed phase, in Unix time
    /// @dev this will create a Voting contract and then add its address to 'votingContracts'
    function createVotingContract(
        address manager,
        string memory description,
        string memory optionADescription,
        string memory optionBDescription,
        uint256 intendedVotingDate,
        uint256 intendedClosingDate
    ) public {
        address votingAddress =
            address(
                new Voting(
                    manager,
                    description,
                    optionADescription,
                    optionBDescription,
                    intendedVotingDate,
                    intendedClosingDate
                )
            );

        votingContracts.push(votingAddress);
    }

    /// Get all the Voting contracts' addresses
    /// @dev returns the 'votingContracts' array
    function getVotingContracts() public view returns (address[] memory) {
        return votingContracts;
    }
}
