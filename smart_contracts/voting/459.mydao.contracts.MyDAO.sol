/*
ganache-cli -m "xxxx..." --blockTime 5

Try with Truffle:
===================
truffle migrate --network development --reset
truffle console // default: --network development

let token = await MyCoin.deployed();
token.address;
token.symbol();
token.name();
(await token.decimals()).toString();
(await token.totalSupply()).toString();

let myDao = await MyDAO.deployed();
...

Try with Remix:
...Copy paste the twoo contracts in Remix or use the Remix extension for VSCode.
*/

// SPDX-License-Identifier: MIT.
pragma solidity ^0.8.7;

//#region Imports

// NOTE (*1): You can import and use MyCoin or OpenZeppelin's IERC20 and ERC20 
// directly (since MyCoin is ERC20) and it has no extra functionality. What matters
// is deploying the DAO with the address of the previously deployed token.
// The initial configuration of the token is in 2_contracts_migration.js but it 
// can be previously deployed manually.
//import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';*1
import "./MyCoin.sol";

//#endregion

/// @title DAO for voting proposals. (for research porpose).
/// @author Esteban H. Somma.
/// @notice A basic voting DAO smart contract for research purposes to understand
/// its inner workings. This is by no means a complete implementation. It also 
/// includes an ERC-20 contract to be used as a DAO governance token.
contract MyDAO {
    //#region Declarations

    // The IERC20 allow us to use MyCoin like our governance token.
    //IERC20 public token;//*1
    MyCoin public token;

    // Voting options.
    enum VotingOptions {
        Yes,
        No
    }

    // Status for the Proposal.
    enum Status {
        Accepted,
        Rejected,
        Pending
    }

    // The proposal to vote.
    struct Proposal {
        // Unique identifier of the proposal.
        uint256 id;
        // Address from the account that create the proposal.
        address author;
        // Creation date, that allow us to set a period of time for allow the voting.
        uint256 createdAt;
        // Number of Votes for Yes. This will allow us set an status for the proposal
        // when number of votes for any option be greater than fifty percent.
        uint256 votesForYes;
        // Number of Votes for No.
        uint256 votesForNo;
        // Status for the Proposal.
        Status status;
        // Name of the proposal.
        string name;
    }

    // List of all proposals.
    mapping(uint256 => Proposal) public proposals;

    // Who already votes for who to avoid vote twice.
    mapping(address => mapping(uint256 => bool)) public votesHistory;

    // Number of governance tokens are deposited like a shares for a
    // shareholder to give a proportional weight to their vote.
    mapping(address => uint256) public shares;

    // Totar of shares in the DAO.
    uint256 public totalShares;

    // Minimum tokens needed to create a proposal.
    // MYC 20.000000000000000000 = cent (like wei) 20,000,000,000,000,000,000
    uint256 private constant CREATE_PROPOSAL_MIN_SHARE = 20 * 10**18;

    // Max time to vote.
    uint256 private constant VOTING_MAX_TIME = 7 days;

    // Proposal index.
    uint256 public proposalIndex;

    //#endregion

    //#region Constructor

    /// @dev Sets the values for {tokenAddress}. tokenAddress is immutable, it can 
    /// only be set once during construction.
    /// @param tokenAddress The address of the governance token to be used in the DAO.
    constructor(address tokenAddress) {
        token = MyCoin(tokenAddress);
        //token = IERC20({token-address}).//*1
    }

    //#endregion

    //#region External functions

    /// @notice Allows you to deposit the amount of tokens specified in {amount} which will
    /// be taken as shares to allow you to vote and create proposals.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) external {
        shares[msg.sender] += amount;
        totalShares += amount;

        (bool success) = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit fail");
    }

    /// @notice Allows the shareholders to withdraw their tokens when the voting period is over.
    /// @param amount The amount of tokens to withdraw.
    ///
    /// Requirements:
    /// - `sender` Must have the amount of tokens that want to withdraw.
    function withdraw(uint256 amount) external {
        require(shares[msg.sender] >= amount, "Amount exceed");

        shares[msg.sender] -= amount;
        totalShares -= amount;

        (bool success) = token.transfer(msg.sender, amount);
        require(success, "Withdraw fail");
    }

    /// @notice Create a new Proposal.
    /// @param name The proposal name.
    ///
    /// Requirements:
    /// - `sender` Must have at least the minimum shares to create a proposal.
    function createProposal(string memory name) external {
        require(
            shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE,
            "Not enough shares"
        );

        // Stores the new proposal.
        proposals[proposalIndex] = Proposal(
            proposalIndex,
            msg.sender, 
            block.timestamp, // solhint-disable-line not-rely-on-time, It handle days as time period (not seconds).
            0,
            0,
            Status.Pending,
            name
        );

        proposalIndex++;
    }

    /// @notice Votes (for or against) the proposal corresponding to {proposalId} assigning
    /// all the shares of the sender as number of votes
    /// @dev If the proposal has more than fifty percent of votes in one option, the contract
    /// need to change the proposal status to Accepted or Rejected.
    ///
    /// @param proposalId The {proposalId} to asign the vote.
    /// @param voteOption VotingOptions.Yes (0) for a positive vote or VotingOptions.No (1)
    /// for a negative vote.
    ///
    /// Requirements:
    /// - `sender` must not have voted the proposal corresponding to {proposalId}.
    /// - `sender` must vote within the specified time period (from proposal creation to
    ///            {VOTING_MAX_TIME}).
    function vote(uint256 proposalId, VotingOptions voteOption) external {
        Proposal storage proposal = proposals[proposalId];

        require(!votesHistory[msg.sender][proposalId], "Already voted");

        require(
            // solhint-disable-next-line not-rely-on-time, It handle days as time period (not seconds).
            block.timestamp <= proposal.createdAt + VOTING_MAX_TIME,
            "Voting period is over"
        );

        votesHistory[msg.sender][proposalId] = true;

        if (voteOption == VotingOptions.Yes) {
            // Yes.
            proposal.votesForYes += shares[msg.sender];

            // If the proposal has more than fifty percent of positive votes, change Accepted.
            if ((proposal.votesForYes * 100) / totalShares > 50) {
                proposal.status = Status.Accepted;
            }
        } else {
            // No.
            proposal.votesForNo += shares[msg.sender];

            // If the proposal has more than fifty percent of negative votes, change Rejected.
            if ((proposal.votesForNo * 100) / totalShares > 50) {
                proposal.status = Status.Rejected;
            }
        }
    }

    //#endregion
}
