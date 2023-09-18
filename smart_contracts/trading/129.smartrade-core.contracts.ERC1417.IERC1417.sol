// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1417 compliant contract.
 *
 * ERC1417 Poll Standard
 * Note: the ERC165 identifier for this interface is 0xc244fea4.
 *
 * For more details and updated information, please see
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1417.md
 */
interface IERC1417 is IERC165 {
    /**
     * @dev Emitted when a person tries to vote without permissions. Useful for
     *  auditing purposes. E.g.: To prevent an admin to revoke permissions;
     *  calculate the result had they not been removed.
     * @param from       User who tried to vote
     * @param proposalId The index of the proposal he voted to
     * @param voteWeight The weight of his vote
     */
    event TriedToVote(address indexed from, uint256 indexed proposalId, uint256 voteWeight);

    /**
     * @dev Emitted when a person votes successfully.
     * @param from       User who successfully voted
     * @param proposalId The index of the proposal he voted to
     * @param voteWeight The weight of his vote
     */
    event CastVote(address indexed from, uint256 indexed proposalId, uint256 voteWeight);

    /**
     * @dev Emitted when a person revokes his vote.
     * @param from       User who successfully unvoted
     * @param proposalId The index of the proposal he unvoted
     * @param voteWeight The weight of his vote
     */
    event RevokedVote(address indexed from, uint256 indexed proposalId, uint256 voteWeight);

    /**
     * @notice Handles the vote logic
     * @dev Updates the appropriate data structures regarding the vote. Stores
     *  the `proposalId` against the user to allow for unvote
     * @param proposalId The index of the proposal in the proposals array
     *
     * Requirements:
     *
     * - `proposalId` must exist.
     *
     * Emits an {CastVote} or {TriedToVote} event.
     */
    function vote(uint256 proposalId) external;

    /**
     * @notice Handles the unvote logic
     * @dev Updates the appropriate data structures regarding the unvote
     *
     * Emits an {RevokedVote} event.
     */
    function revokeVote() external;

    /**
     * @notice Gets the name of the poll e.g.: "Admin Election for Autumn 2018"
     * @dev Set the name in the constructor of the poll
     * @return the name of the poll
     */
    function name() external view returns (string memory);

    /**
     * @notice Gets the type of the Poll e.g.: Token (XYZ) weighted poll
     * @dev Set the poll type in the constructor of the poll
     * @return the type of the poll
     */
    function pollType() external view returns (string memory);

    /**
     * @notice Gets the proposal names
     * @dev Limit the proposal count to 32 (for practical reasons), loop and
     *  generate the proposal list
     * @return the list of names of proposals
     */
    function getProposals() external view returns (bytes32[] memory);

    /**
     * @notice Returns a boolean specifying whether the user can vote
     * @dev Implement logic to enable checks to determine whether the user can vote
     *  if using eip-1261, use protocol addresses and interface (IERC1261) to enable
     *  checking with attributes.
     * @param to The person who can vote/not
     * @return a boolean as to whether the user can vote
     */
    function canVote(address to) external view returns (bool);

    /**
     * @notice Returns a boolean specifying whether all voters cast
     * @dev Implement logic to enable checks to determine whether all voters cast.
     *  This function is not original from ERC1417.
     * @return a boolean as to whether all voters cast
     */
    function allVote() external view returns (bool);

    /**
     * @notice Gets the vote weight of the proposalId
     * @dev Returns the current cumulative vote weight of a proposal (`proposalId`)
     * @param proposalId The index of the proposal in the proposals array
     * @return the cumulative vote weight of the specified proposal
     */
    function getVoteTally(uint256 proposalId) external view returns (uint256);

    /**
     * @notice Gets the no. of voters who voted for the proposal
     * @dev Use a struct to keep a track of voteWeights and voterCount
     * @param proposalId The index of the proposal in the proposals array
     * @return the voter count of the people who voted for the specified proposal
     */
    function getVoterCount(uint256 proposalId) external view returns (uint256);

    /**
     * @notice Calculates the vote weight associated with the person `to`
     * @dev Use appropriate logic to determine the vote weight of the individual
     *  For sample implementations, refer to end of the eip
     * @param to The person whose vote weight is being calculated
     * @return the vote weight of the individual
     */
    function calculateVoteWeight(address to) external view returns (uint256);

    /**
     * @notice Gets the leading proposal at the current time
     * @dev Calculate the leading proposal at the current time
     *  For practical reasons, limit proposal count to 32.
     * @return the index of the proposal which is leading
     */
    function winningProposal() external view returns (uint256);

    /**
     * @notice Gets the logic to be used in a poll's `canVote` function
     *  e.g.: "XYZ Token | US & China(attributes in erc-1261) | Developers(attributes in erc-1261)"
     * @dev Set the Voterbase logic in the constructor of the poll
     * @return the voterbase logic
     */
    function getVoterBaseLogic() external view returns (string memory);

    /**
     * @notice Gets the start time for the poll
     * @dev Set the start time in the constructor of the poll as Unix Standard Time
     * @return start time as Unix Standard Time
     */
    function getStartTime() external view returns (uint256);

    /**
     * @notice Gets the end time for the poll
     * @dev Set the end time in the constructor of the poll as Unix Time or specify duration in constructor
     * @return end time as Unix Standard Time
     */
    function getEndTime() external view returns (uint256);

    /**
     * @notice Retuns the list of entity addresses (eip-1261) used for perimissioning purposes.
     * @dev Addresses list can be used along with IERC1261 interface to define the logic inside `canVote()` function
     * @return the list of addresses of entities
     */
    function getProtocolAddresses() external view returns (address[] memory);

    /**
     * @notice Gets the vote weight against all proposals
     * @dev Limit the proposal count to 32 (for practical reasons), loop and generate the vote tally list
     * @return the list of vote weights against all proposals
     */
    function getVoteTallies() external view returns (uint256[] memory);

    /**
     * @notice Gets the no. of people who voted against all proposals
     * @dev Limit the proposal count to 32 (for practical reasons), loop and generate the vote count list
     * @return the list of voter count against all proposals
     */
    function getVoterCounts() external view returns (uint256[] memory);

    /**
     * @notice For single proposal polls, returns the total voterbase count.
     *  For multi proposal polls, returns the total vote weight against all proposals
     *  this is used to calculate the percentages for each proposal
     * @dev Limit the proposal count to 32 (for practical reasons), loop and generate the voter base denominator
     * @return an integer which specifies the above mentioned amount
     */
    function getVoterBaseDenominator() external view returns (uint256);
}
