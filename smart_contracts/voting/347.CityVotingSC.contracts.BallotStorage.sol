// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract BallotStorage {
	
	struct Candidate {
		/// @notice Unique candidate id
		uint id;

		/// @notice Name of the candidate
		string name;

		/// @notice Amount of votes cast for the candidate
		uint votes;
	}

	struct Election {
		/// @notice Unique election id
		uint id;

		/// @notice Name of the election
		string name;

		/// @notice Current unique candidate id
		uint currentCandidateId;

		/// @notice List of candidates running in election
		Candidate[] candidates;
	}

	struct Issue {
		/// @notice Unique issue id
		uint id;

		/// @notice Name of the issue
		string name;

		/// @notice Amount of votes cast for the issue
		uint forVotes;

		/// @notice Amount of votes cast against the issue
		uint againstVotes;
	}

	struct Ballot {
		/// @notice Unique ballot id
		uint id;

		/// @notice Name of the ballot
		string name;

		/// @notice status of the ballot, CLOSED, OPEN, or COMPLETE
		uint status;

		/// @notice Current unique election id
		uint currentElectionId;

		/// @notice Current unique issue id
		uint currentIssueId;

		/// @notice List of elections on the ballot
		Election[] elections;

		/// @notice List of issues on the ballot
		Issue[] issues;
	}

	/// @notice State of ballot variables for Ballot.status
	uint CLOSED = 0;
	uint OPEN = 1;
	uint COMPLETE = 2;

    /// @notice Current unique ballot ID
	uint currentBallotId;

    /// @notice List of all ballots
	Ballot[] ballotsList;

}
