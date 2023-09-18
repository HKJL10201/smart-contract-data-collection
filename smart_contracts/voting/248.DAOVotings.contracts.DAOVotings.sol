//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title Votings smart-contract based on DAO
/// @author AkylbekAD
/// @notice You can participate in Votings depositing ExampleToken (EXT) 
/// @dev Could be redeployed with own ERC20 token and other parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @dev Throw this error if account without rights try to use chairman functions
error SenderDontHasRights(address sender);

/// @dev Throw this error if voting doesn`t get minimal quorum of votes
error MinimalVotingQuorum(uint256 votingIndex, uint256 votingQuorum);

contract DAOVotings is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter public Counter;

    /// @notice Person allowed to create Votings
    address public chairman;

    /// @notice ERC20 contract address tokens avaliable to deposit
    address public erc20address;

    /// @notice Minimum amount of votes for Voting to be accomplished
    uint256 public minimumQuorum;

    /// @notice Minimum period of time for each Voting
    uint256 public minimumDuration = 3 days;

    /// @dev Bytes format for ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Bytes format for CHAIRMAN role
    bytes32 public constant CHAIRMAN = keccak256("CHAIRMAN");

    /// @dev Structure of each proposal Voting
    struct Voting {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 debatingPeriodDuration;
        address contractAddress;
        bytes callData;
        bool votingFinished;
        mapping (address => uint256) votes;
    }

    /// @dev Structure of each voter info
    struct Voter {
        uint256 votingPower;
        uint256 depositDuration;
    }

    /// @notice View voter`s voting power and deposit freeze time
    /// @dev Voter`s info could change only be themselfs 
    mapping (address => Voter) public voterInfo;

    /// @notice View Voting`s info by it`s index
    /// @dev Mapping stores all Votings info
    mapping (uint256 => Voting) public getProposal;

    event ProposalStarted(string description, uint256 votingIndex, uint256 debatingPeriodDuration, address contractAddress, bytes callData);
    event VoteGiven(address voter, uint256 votingIndex, bool decision, uint256 votingPower);
    event ProposalFinished(uint256 votingIndex, bool proposalCalled);

    /// @dev First chairman is deployer, must input token address and minimum quorum for votings
    constructor(address erc20, uint256 quorum) {
        chairman = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setRoleAdmin(CHAIRMAN, ADMIN);
        erc20address = erc20;
        minimumQuorum = quorum;
    }

    /// @dev Modifier checks sender to be Chairman or Admin, otherwise reverts with error
    modifier isChairman() {
        if(!hasRole(ADMIN, msg.sender) && !hasRole(CHAIRMAN, msg.sender)) {
            revert SenderDontHasRights(msg.sender);
        }
        _;
    }

    /// @dev Chaiman or Admin can set a minimum Voting Quorum
    function setMinimumQuorum(uint256 amount) external isChairman {
        minimumQuorum = amount;
    }

    /// @dev Chaiman or Admin can change an ERC20 token address
    function setERC20address(address contractAddress) external isChairman {
        erc20address = contractAddress;
    }

    /// @notice Deposit tokens to have voting power in Votings
    /// @dev Users have to approve tokens to contract first
    /// @param amount is amount of approved tokens by user to contract
    function deposit(uint256 amount) external {
        IERC20(erc20address).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        voterInfo[msg.sender].votingPower += amount;
        voterInfo[msg.sender].depositDuration = block.timestamp;
    }

    /// @notice Only chairman or admin can start new Votings with proposal
    /// @dev Creates new voting and emits ProposalStarted event
    /// @param duration value cant be less then minimumDuration value
    /// @param contractAddress is address of contract callData on which should be called
    /// @param callData is hash which be decoded to abi and parametres to be called at contract
    function addProposal(string memory description, uint256 duration, address contractAddress, bytes memory callData) public isChairman {
        Counter.increment();
        uint256 index = Counter.current();

        getProposal[index].description = description;
        getProposal[index].callData = callData;
        getProposal[index].contractAddress = contractAddress;

        if (duration < minimumDuration) {
            getProposal[index].debatingPeriodDuration = block.timestamp + minimumDuration;
        } else {
            getProposal[index].debatingPeriodDuration = block.timestamp + duration;
        }

        emit ProposalStarted(description, index, getProposal[index].debatingPeriodDuration, contractAddress, callData);
    }

    /// @notice Make your decision 'true' to vote for or 'false' to vote against with deposoted tokens
    /// @dev Voters can vote only once at each voting
    /// @param votesAmount is amount of deposited tokens or 'votingPower'
    /// @param decision must be 'true' or 'false'
    function vote(uint256 votingIndex, uint256 votesAmount, bool decision) external {
        require(block.timestamp < getProposal[votingIndex].debatingPeriodDuration, "Voting have been ended");
        require(votesAmount <= voterInfo[msg.sender].votingPower, "Not enough deposited tokens");
        require(getProposal[votingIndex].votes[msg.sender] == 0, "You have already voted");

        if (decision) {
            getProposal[votingIndex].votesFor += votesAmount;
        } else {
            getProposal[votingIndex].votesAgainst += votesAmount;
        }

        if (voterInfo[msg.sender].depositDuration < getProposal[votingIndex].debatingPeriodDuration) {
            voterInfo[msg.sender].depositDuration = getProposal[votingIndex].debatingPeriodDuration;
        }

        getProposal[votingIndex].votes[msg.sender] += votesAmount;

        emit VoteGiven(msg.sender, votingIndex, decision, votesAmount);
    }

    /// @notice Finish voting and do proposal call
    /// @dev Calls proposalCall function with voting parameters and emits ProposalCalled event
    function finishProposal(uint256 votingIndex) external {
        require(block.timestamp >= getProposal[votingIndex].debatingPeriodDuration, "Debating period didnt pass");
        require(!getProposal[votingIndex].votingFinished, "Proposal voting was already finished or not accepted");

        uint256 votingQuorum = getProposal[votingIndex].votesFor + getProposal[votingIndex].votesAgainst;

        if (votingQuorum < minimumQuorum) {
            getProposal[votingIndex].votingFinished = true;

            emit ProposalFinished(votingIndex, false);

            revert MinimalVotingQuorum(votingIndex, votingQuorum);
        }

        if (getProposal[votingIndex].votesFor > getProposal[votingIndex].votesAgainst) {
            proposalCall(getProposal[votingIndex].contractAddress, getProposal[votingIndex].callData);

            emit ProposalFinished(votingIndex, true);
        }

        getProposal[votingIndex].votingFinished = true;
    }

    /// @notice Returns deposited tokens to sender if duration time passed
    function returnDeposit() external {
        require(voterInfo[msg.sender].depositDuration < block.timestamp, "Deposit duration does not pass");

        uint256 depositTokens = voterInfo[msg.sender].votingPower;
        voterInfo[msg.sender].votingPower = 0;
        IERC20(erc20address).transfer(msg.sender, depositTokens);
    }

    function startChairmanElection(address newChairman, uint256 duration) external {
        require(hasRole(ADMIN, msg.sender), "You are not an Admin");

        bytes memory callData = abi.encodeWithSignature("changeChairman(address)", newChairman);
        addProposal("Proposal for a new Chairman", duration, address(this), callData);
    }

    /// @notice Get last voting index or number of all created proposals
    function getLastIndex() external view returns(uint256) {
        return Counter.current();
    }

    /// @notice Get amount of votes made by account at Voting
    function getVotes(uint256 votingIndex, address voter) external view returns(uint256) {
        return getProposal[votingIndex].votes[voter];
    }

    /// @dev Function that called if proposal voting is astablished succesfull
    function proposalCall(address contractAddress, bytes memory callData) private {
        (bool success, ) = contractAddress.call{value: 0} (
            callData
        );
        require(success, "Error proposalcall");
    }

    /// @dev Can only be called throw addProposal function by voting
    function changeChairman(address newChairman) external {
        require(msg.sender == address(this), "Must called throw proposal");
        chairman = newChairman;
    }
}
