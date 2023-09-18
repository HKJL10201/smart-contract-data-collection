// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.13;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";


/**
 * @title A Voting smart contract
 * @author Maxence Guillemain d'Echon
 * @notice You can use this contract to generate voting sessions
**/
contract Voting is Ownable {

    /** STRUCTS & ENUMS **/

    struct Voter {
        bool isRegistered;
        
        /**
         * Replaces 'bool hasVoted'
         * In order to handle ties - for which the voting session is re-openned.
        **/
        uint8 votedProposalId;
        uint32 votesNb;

        /**
         * Added to handle bribes (i.e. a Voter buying the vote of an another Voter)
         * Any value different from 0 indicates that the Voter is willing to sell her vote at the price of {bribe} Wei
         * The bribe can be defined in {ProposalsRegistrationStarted} phase using the {defineBribe()} function.
         * The bribe can be sent in {VotingSessionStarted} phase using the {bribe()} function. 
         * A Voter cannot be brided if she has already voted. Once bribed, the Voter cannot vote anymore. 
        **/
        uint bribe; 
    }

    struct Proposal {
        string description;
        uint32 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /** STATE VARIABLES **/

    WorkflowStatus private status;
    uint32 private totalVotesCount;
    mapping (address => Voter) private voters;
    Proposal[] private proposals;
    uint8 private winningProposalId;
    uint8 constant private MAX_PROPOSALS_NB = 100; /* To counter Gas Limit DoS */
    bool private isAtLeastOneVoter;

    /**
     * To handle ties.
     * If there are many more Voters than Proposals, ties are very unlikely to happen.
     * Here ties are handled by starting a new voting session between the tie Proposals only.
     * Thus, the WorkflowStatus is rewinded to VotingSessionStarted.
    **/
    bool private isWinnerFound;
    uint16 private votingSessionsNb;

    /** EVENTS **/

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus nextStatus);
    event ProposalRegistered(uint8 proposalId);
    event Voted(address voterAddress, uint8 proposalId);
    event Tie();

    /** DEFAULT FUNCTIONS **/
    /**
     * @notice Initializes the contract.
    **/
    constructor() Ownable() {
        status = WorkflowStatus.RegisteringVoters;
        votingSessionsNb = 1;
    }

    /**
     * @notice Initializes the contract.
    **/
    receive() external payable {
    }

    /** MODIFIERS **/

    modifier onlyStatus(WorkflowStatus _status)  {
        require (status == _status, "The current status does not allow this operation");
        _;
    }

    modifier onlyRegisteredVoters() {
        require (voters[msg.sender].isRegistered, "Operation not allowed : You are not a registered voter");
        _;
    }

    /** FUNCTIONS **/

    /**
     * @notice During any phase (except {VotesTallied}), allows the owner to switch to the next phase.
     * If the status is {VotingSessionEnded}, the votes are tallied.
     * Then, the status is switched to {VotesTallied}, excepted if they is a tie, in which case, the status is
     * rewinded to VotingSessionStarted, and a new voting session is started with only the ties Proposals.
    **/
    function nextPhase() external onlyOwner {
        require (status != WorkflowStatus.VotesTallied, "Operation not allowed : vote is already tallied");

        if (status == WorkflowStatus.RegisteringVoters) {
            require (isAtLeastOneVoter, "There are no voters !");
            status = WorkflowStatus.ProposalsRegistrationStarted;
            emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, status);
        }
        else if (status == WorkflowStatus.ProposalsRegistrationStarted) {
            require (proposals.length != 0, "There are no proposals !");
            status = WorkflowStatus.ProposalsRegistrationEnded;
            emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, status);
        }
        else if (status == WorkflowStatus.ProposalsRegistrationEnded) {
            status = WorkflowStatus.VotingSessionStarted;
            emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, status);
        }
        else if (status == WorkflowStatus.VotingSessionStarted) {
            status = WorkflowStatus.VotingSessionEnded;
            emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, status);
        }
        else if (status == WorkflowStatus.VotingSessionEnded) {
            _tallyHandleTie();
            if (isWinnerFound) { 
                status = WorkflowStatus.VotesTallied;
                emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, status);
            }
            else { // Rewind the status to start a new Voting session 
                status = WorkflowStatus.VotingSessionStarted;
                emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, status);
                emit Tie();
            }
        }
    }

    /**
     * @notice During the {RegisteringVoters} phase, allows the Owner to register a Voter.
     * @param _addr the address of the Voter to register.
    **/
    function registerVoter(address _addr) external onlyOwner onlyStatus(WorkflowStatus.RegisteringVoters) {
        require (_addr != address(0), "You cannot register the null address");

        voters[_addr] = Voter(true, 0, 0, 0);
        if (!isAtLeastOneVoter)
            isAtLeastOneVoter = true;

        emit VoterRegistered(_addr);
    }

    /**
    * @notice After the {RegisteringVoters} phase, allows the Owner to get a Voter.
    * @param _addr the address of the Voter to get.
    **/
    function getVoter(address _addr) external view returns(Voter memory) {
        require (status != WorkflowStatus.RegisteringVoters, "The current status does not allow this operation");
        return voters[_addr];
    }

    /**
     * @notice During the {ProposalsRegistrationStarted} phase, allows a registered Voter to register a Proposal.
     * @param _description the description of the proposal to register. 
    **/
    function registerProposal(string calldata _description) external onlyStatus(WorkflowStatus.ProposalsRegistrationStarted) onlyRegisteredVoters {
        require (bytes(_description).length != 0, "Please add the description of your proposal");
        uint8 _id = uint8(proposals.length); 
        require (_id < MAX_PROPOSALS_NB, "Maximum nb of proposals reached");  /* To counter Gas Limit DoS */
        
        proposals.push(Proposal(_description, 0)); 

        emit ProposalRegistered(_id);
    }

    /**
     * @notice During the {ProposalsRegistrationStarted} phase, allows a registered Voter to sets the minimum 
     * bribe value that she requests to sell her vote.
     * @param _value the minimum bribe value requested to sell the vote.
    **/
    function defineBribe(uint _value) external onlyStatus(WorkflowStatus.ProposalsRegistrationStarted) onlyRegisteredVoters {
        voters[msg.sender].bribe = _value;
    }

    /**
    * @notice During the {VotingSessionStarted} phase, allows a Voter to get the proposals.
    **/
    function getProposals() external  onlyStatus(WorkflowStatus.VotingSessionStarted) onlyRegisteredVoters view returns(Proposal[] memory) {
        return proposals;
    }

    /**
     * @notice During the {VotingSessionStarted} phase, allows a registered Voter to vote for any registered Proposal.
     * Proposals are identified by a unique _id.
     * @param _id the id of the proposal to vote for.
    **/
    function vote(uint8 _id) external onlyStatus(WorkflowStatus.VotingSessionStarted) onlyRegisteredVoters {
        require (voters[msg.sender].votesNb < votingSessionsNb, "You can only vote once");
        require (_id < proposals.length, "The id does not match to any proposal");

        proposals[_id].voteCount++;
        voters[msg.sender].votesNb++;
        voters[msg.sender].votedProposalId = _id;

        emit Voted(msg.sender, _id);
    }

    /**
     * @notice During the {VotingSessionStarted} phase, allows a registered Voter to send a bribe 
     * to another registered Voter.
     * @param _addr the address of the Voter to bribe.
     * @param _id the id of the proposal to vote for.
    **/
    function bribe(address _addr, uint8 _id) external payable onlyStatus(WorkflowStatus.VotingSessionStarted) onlyRegisteredVoters {
        require (voters[_addr].bribe != 0, "You cannot bribe this address");
        require (voters[_addr].votesNb < votingSessionsNb, "You can only bribe an address which has not voted yet");
        require (voters[_addr].bribe <= msg.value, "Your bribe is not enough");
        require (_id < proposals.length, "The id does not match to any proposal");

        /** To prevent reentrency attacks, the voteCount is updated before sending the bribe. */
        proposals[_id].voteCount++;
        voters[_addr].votesNb++;
        voters[_addr].votedProposalId = _id;

        (bool success, ) = _addr.call{value:msg.value, gas: 25000}("");
        require (success, "Bribe failed !");

        emit Voted(_addr, _id);
    }

    /**
     * @dev Internal function to tally the votes, handling ties.
     * Also counts the total number of votes and stores it in {totalVotesCount}.
    **/
    function _tallyHandleTie() internal {
        uint32 _maxCount;
        uint32 _totalVotesCount;
        uint8[MAX_PROPOSALS_NB] memory _winningProposalIds;
        Proposal[MAX_PROPOSALS_NB] memory _winningProposals;
        uint8 _winningProposalsNb;

        // Finds the Proposal(s) with the greatest vote count, and stores them and their _ids in _winningProposals and _winningProposalIds
        for (uint8 _id=0; _id<proposals.length; _id++) {
            if (proposals[_id].voteCount >= _maxCount) {
                // If the winning proposals have less votes than the currently watched proposal, remove them from the winning list 
                if (proposals[_id].voteCount > _maxCount)
                    _winningProposalsNb = 0;
                _winningProposalIds[_winningProposalsNb] = _id;
                _winningProposals[_winningProposalsNb] = proposals[_id];
                _winningProposalsNb++;
                _maxCount = proposals[_id].voteCount;
            }
            _totalVotesCount += proposals[_id].voteCount;
        }
        totalVotesCount = _totalVotesCount;

        if (_winningProposalsNb == 1) { 
            // There is no Tie, we set the Winner.
            winningProposalId = _winningProposalIds[0];
            isWinnerFound = true;
        }
        else {
            // There is a Tie, the list of Proposals is replaced by the list of the winning Proposals.
            while (proposals.length != 0)
                proposals.pop();
            uint8 _id = 0;
            while (proposals.length != _winningProposalsNb) {
                proposals.push(_winningProposals[_id++]);
                proposals[proposals.length - 1].voteCount = 0;
            }
            votingSessionsNb ++;
        }
    }

    /**
     * @notice During any phase, allows anybody to see current phase.
     * @return status a string containing the status.
    **/
    function getStatus() external view returns(string memory) {
        string memory str;
        if (status == WorkflowStatus.RegisteringVoters) {
            str = "RegisteringVoters";
        }
        else if (status == WorkflowStatus.ProposalsRegistrationStarted) {
            str = "ProposalsRegistrationStarted";
        }
        else if (status == WorkflowStatus.ProposalsRegistrationEnded) {
            str = "ProposalsRegistrationEnded";
        }
        else if (status == WorkflowStatus.VotingSessionStarted) {
            str = "VotingSessionStarted";
        }
        else if (status == WorkflowStatus.VotingSessionEnded) {
            str = "VotingSessionEnded";
        }
        else if (status == WorkflowStatus.VotesTallied) {
            str = "VotesTallied";
        }
        return str;
    }

    /**
     * @notice During the {VotingSessionStarted} phase and after, allows a registered Voter to see the vote  
     * of another registered Voter, giving only her address.
     * @param _addr the address to get the vote of.
     * @return _id the id of the voted proposal.
    **/
    function getVote(address _addr) external view onlyRegisteredVoters returns(uint8) {
        require (voters[_addr].votesNb >= votingSessionsNb, "The address given has not voted.");
        return voters[_addr].votedProposalId;
    }

    /**
     * @notice During the {VotesTallied} phase, allows anybody to get the winning Proposal id.
     * @return winningProposalId the id of the winning proposal.
    **/
    function getWinner() external view onlyStatus(WorkflowStatus.VotesTallied) returns(uint8) {
        return winningProposalId;
    }
}