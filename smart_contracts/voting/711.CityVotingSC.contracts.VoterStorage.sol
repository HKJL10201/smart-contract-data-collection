// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VoterStorage {
    struct Voter {
		/// @notice Address of registered voter
		address voterAddress;
	}

	struct VoteRecord {
		/// @notice Ballot id 
		uint ballotId;

		/// @notice Records if address has voted for this ballot
		mapping(address => bool) hasVoted;
	}

    /// @notice Total number of registered voters
	uint voterCount;

    /// @notice Voting roll of all registered voters
	mapping(address => Voter) public voterRoll;

	/// @notice Records if voters have voted on ballot by ballot id
	VoteRecord[] voteRecordList;

}
