// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./AccessManager.sol";

contract VotingHubV1 is AccessManager {
    /// @notice The name of this contract
    string public constant name = "XDC Network Voting Smart Contract V1";

    /// @notice number of proposals in existance
    uint public proposalCount;

    /// @notice Total value burned in tolls
    uint public totalTollBurned;

    /// @notice Total value collected in tolls
    uint public totalTollCollected;

    /// @notice address of the Community Treasury
    address public TREASURY_ADDRESS;

    /// @notice toll burn rate
    uint public TOLL_BURN_RATE;

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        pending,
        active,
        canceled,
        finished
    }

    /// @notice Voter possible choices
    enum Choice {
        support,
        against,
        abstain
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal
        Choice voterChoice;
        /// @notice The number of votes the voter had, which were cast
        uint256 votes;
    }

    struct Proposal {
        /// @notice Proposal unique ID
        uint256 id;
        /// @notice Proposer address
        address proposer;
        /// @notice Flag if proposer is an Authorized individual
        bool isProposerAuth;
        /// @notice Timestamp at which the proposal will be open to new votes
        uint256 opens;
        /// @notice Timestamp at which the proposal will be closed to new votes
        uint256 closes;
        /// @notice Number of native coins necessary to cast a vote
        uint256 toll;
        /// @notice Passing Vote Percentage
        uint passingPerc;
        /// @notice Current number of votes in favor of this proposal
        uint forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;
        /// @notice Null Votes
        uint nullVotes;
        /// @notice Proposal State
        ProposalState currentState;
    }

    /// @notice Receipts of ballots for the entire set of voters
    mapping (address => mapping (uint => Receipt)) public receipts;

    /// @notice Proposal unique hash
    mapping (uint => string) private proposalUniqueHash;

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;
    
    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint256 indexed id, address indexed proposer, uint256 opens, uint256 closes, string uniqueHash);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address indexed voter, uint proposalId, Choice voterChoice, uint256 votes);

    /// @notice An event emitted when a proposal doesn't reach the minimum passing percentage
    event ProposalFailed(uint256 indexed id);

    /// @notice An event emitted when a proposal reach the minimum passing percentage
    event ProposalPassed(uint256 indexed id, uint256 totalVotes, uint256 votesInFavor);

    /**
     * @notice Construct a new VotingHubV1 contract 
     * @param _treasury - community treasury wallet address 
     **/
    constructor(address _treasury) {
        TREASURY_ADDRESS = _treasury;
        TOLL_BURN_RATE = 0;
        owner = msg.sender;
        totalTollBurned = 0;
        totalTollCollected = 0;
    }

    /**
     * @notice Set TOLL_BURN_RATE 
     * @param _rate - Must be a value between 0 and 100
     **/
    function setTollBurnRate (uint _rate) public onlyOwner {
        require(_rate <= 100, "VotingHubV1::setTollBurnRate: toll burn rate must be between 0 and 100");
        require(_rate >= 0, "VotingHubV1::setTollBurnRate: toll burn rate must be between 0 and 100");
        TOLL_BURN_RATE = _rate;
    }

    /**
     * @notice Get proposal unique hash 
     * @param _proposalId - Is the id of proposal
     * @return string - proposal unique hash used to identify proposal in the voting dapp backend
     **/
    function getUniqueHash (uint256 _proposalId) public view onlyAuthorized returns (string memory)  {
        return proposalUniqueHash[_proposalId];
    }

    /**
     * @notice Create a new proposal 
     * @param _description - Proposal description
     * @param _opens - Timestamp at which the proposal will be open to new votes
     * @param _closes - Timestamp at which the proposal will be closed to new votes
     * @param _votingToll - Number of native coins necessary to cast a vote
     * @param _passingPerc - Passing Vote Percentage
     * @param _uniqueHash - Proposal unique hash used to identify proposal in the voting dapp backend
     * @return uint - proposal id
     **/
    function propose(string memory _description, uint256 _opens, uint256 _closes, uint256 _votingToll, uint256 _passingPerc, string memory _uniqueHash) public notContract returns (uint) {
        
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = proposals[latestProposalId].currentState;
          require(proposersLatestProposalState != ProposalState.active, "VotingHubV1::propose: one live proposal per proposer, found an already active proposal");
        }

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            isProposerAuth: isAuthorized(msg.sender),
            opens: _opens,
            closes: _closes,
            toll: _votingToll * 10 ** 18,
            passingPerc: _passingPerc,
            forVotes: 0,
            againstVotes: 0,
            nullVotes: 0,
            currentState: ProposalState.pending
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;
        proposalUniqueHash[newProposal.id] = _uniqueHash;

        emit ProposalCreated(newProposal.id, newProposal.proposer, newProposal.opens, newProposal.closes, _description);
        return newProposal.id;        
    }

    /**
     * @notice Calculate toll that will be send to the zero address 
     * @param _toll - voting toll
     * @dev this is a helper function to calculate the toll that will be burned
     **/
    function _calculateTollBurned(uint256 _toll) internal view returns (uint) {
        return (_toll * TOLL_BURN_RATE) / 100;
    }

    /**
     * @notice Cast a vote on a proposal 
     * @param _proposalId - Is the id of proposal
     * @param _support - Is a boolean that represent the vote choice
     **/
    function castVote(uint256 _proposalId, bool _support) public notContract payable {
        require(proposals[_proposalId].currentState != ProposalState.canceled, "VotingHubV1::castVote: proposal is canceled");
        _updatedStatus(_proposalId);
        require(msg.value == proposals[_proposalId].toll, "VotingHubV1::castVote: toll amount is not correct");
        totalTollCollected = add256(totalTollCollected, msg.value);
        payable(address(0)).transfer(_calculateTollBurned(msg.value));
        totalTollBurned = add256(totalTollBurned, _calculateTollBurned(msg.value));
        payable(address(TREASURY_ADDRESS)).transfer(sub256(msg.value, _calculateTollBurned(msg.value)));
        return _castVote(msg.sender, _proposalId, _support);
    }

    /**
     * @notice Abstain from voting but still contribute a voting toll
     * @param _proposalId - Is the id of proposal
     **/

    function castVote(uint256 _proposalId) public notContract payable {
        require(proposals[_proposalId].currentState != ProposalState.canceled, "VotingHubV1::castVote: proposal is canceled");
        _updatedStatus(_proposalId);
        require(msg.value == proposals[_proposalId].toll, "VotingHubV1::castVote: toll amount is not correct");
        totalTollCollected = add256(totalTollCollected, msg.value);
        payable(address(0)).transfer(_calculateTollBurned(msg.value));
        totalTollBurned = add256(totalTollBurned, _calculateTollBurned(msg.value));
        payable(address(TREASURY_ADDRESS)).transfer(sub256(msg.value, _calculateTollBurned(msg.value)));
        return _castVote(msg.sender, _proposalId);
    }

    function _castVote(address _voter, uint256 _proposalId, bool _support) internal {
        require(proposals[_proposalId].currentState == ProposalState.active, "VotingHubV1::castVote: voting is closed");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = receipts[_voter][_proposalId];
        require(receipt.hasVoted == false, "VotingHubV1::castVote: voter already voted");

        if(_support) {
            proposal.forVotes = add256(proposal.forVotes, 1);
            receipt.voterChoice = Choice.support;
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, 1);
            receipt.voterChoice = Choice.against;
        }

        receipt.hasVoted = true;
        receipt.votes = 1;

        emit VoteCast(_voter, proposal.id, receipt.voterChoice, receipt.votes);
    }

    function _castVote(address _voter, uint256 _proposalId) internal {
        require(proposals[_proposalId].currentState == ProposalState.active, "VotingHubV1::castVote: voting is closed");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = receipts[_voter][_proposalId];
        require(receipt.hasVoted == false, "VotingHubV1::castVote: voter already voted");

        proposal.nullVotes = add256(proposal.nullVotes, 1);
        receipt.voterChoice = Choice.abstain;

        receipt.hasVoted = true;
        receipt.votes = 1;

         emit VoteCast(_voter, proposal.id, receipt.voterChoice, receipt.votes);
    }

    /**
     * @notice Get the receipt of a voter on a proposal
     * @param _proposalId - Is the id of proposal
     * @param _voter - Is the address of the voter
     * @return Receipt - The receipt of the voter on the proposal
     **/
    function getReceipt(uint256 _proposalId, address _voter) public view returns (Receipt memory) {
        return receipts[_voter][_proposalId];
    }

    /**
     * @notice Get the proposal by id
     * @param _proposalId - Is the id of proposal
     * @return Proposal - It returns the proposal struct with all its details
     **/
    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function _updatedStatus(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.closes < block.timestamp) {
            proposal.currentState = ProposalState.finished;
        } else if(proposal.opens > block.timestamp) {
            proposal.currentState = ProposalState.pending;
        } else {
            proposal.currentState = ProposalState.active;
        }
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "VotingHubV1::SafeMath: addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "VotingHubV1::SafeMath: subtraction underflow");
        return a - b;
    }

    /**
     * @notice Emit an event announcing the results of a proposal
     * @param _proposalId - Is the id of proposal
     **/
    function announceResults(uint256 _proposalId) public {
        _updatedStatus(_proposalId);
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.currentState == ProposalState.finished, "VotingHubV1::closeProposal: proposal is not finished");
        require(msg.sender == proposal.proposer, "VotingHubV1::closeProposal: only proposer can announce results");
        _checkProposal(_proposalId);
    }

    /**
     * @notice Protected function to emit an event announcing the results of a proposal
     * @param _proposalId - Is the id of proposal
     **/
    function protectedAnnounceResults(uint256 _proposalId) public onlyAuthorized {
        _updatedStatus(_proposalId);
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.currentState == ProposalState.finished, "VotingHubV1::closeProposal: proposal is not finished");
        _checkProposal(_proposalId);
    }

    function _checkProposal(uint256 _proposalId) private {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = add256(proposal.forVotes, proposal.againstVotes);
        uint forPercentage = proposal.forVotes * 100 / totalVotes;
        if (forPercentage > proposal.passingPerc) {
            emit ProposalPassed(proposal.id, add256(proposal.forVotes, proposal.againstVotes), proposal.forVotes);
        } else {
            emit ProposalFailed(proposal.id);
        }
    }

    /**
     * @notice Function to allow proposer can cancel his proposal
     * @param _proposalId - Is the id of proposal
     **/
    function cancelProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "VotingHubV1::cancelProposal: only proposer can cancel");
        require(proposal.currentState == ProposalState.active, "VotingHubV1::cancelProposal: proposal is not active");
        proposal.currentState = ProposalState.canceled;
        emit ProposalFailed(proposal.id);
    }

    /**
     * @notice Function to allow authorized individuals (and contract owner) to cancel a proposal
     * @param _proposalId - Is the id of proposal
     **/
    function protectedCancelProposal(uint256 _proposalId) public onlyAuthorized {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.currentState == ProposalState.active, "VotingHubV1::cancelProposal: proposal is not active");
        proposal.currentState = ProposalState.canceled;
        emit ProposalFailed(proposal.id);
    }

    /**
     * @notice In a few cases, residual funds may be left in the contract. This function allows the owner to withdraw them.
     * @dev This function is only callable by the owner. 
     * @dev This function is only callable if there are funds left in the contract.
    **/
     function withdrawRemaining() external onlyOwner {
        require(address(this).balance > 0, "VotingHubV1::withdrawnRemaining: no balance to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }
}

