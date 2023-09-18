// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./OpenZeppelin/access/Ownable.sol";

/**
 * @title Smart voting contract with only one choice per voter registered in a white list
 * @notice You can use this contract for a simple vote
 * @dev All features have been verified with Truffle are functional without side effects. We have chosen to use Ownable from OpenZeppelin library.
 */
contract Voting is Ownable {

    /// @dev arrays for draw, uint for single
    uint[] winningProposalsID;
    Proposal[] winningProposals;
    uint winningProposalID;
    
    /**
     * @notice Structure of a voter to know if he is registered, if he voted and the chosen proposal
     * @dev Boolean for registration and voting, voted proposal id
     */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /**
     * @notice Structure of a proposal with its description and number of votes
     * @dev String for description and uint to count the number of votes per proposal
     */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /**
     * @notice Allows us to know where we are in the contract, more precisely we talk about the status, a follow-up
     * @dev The owner of contract proceeds to the status change according to the different scenarios, represented by an enum
     */
    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] public proposalsArray;
    mapping (address => Voter) private voters;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    /**
     * @notice Only voters admitted to the white list can perform certain actions
     * @dev If a voter is registered then it can execute some functions, otherwise an error message is displayed instead
     */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // ::::::::::::: GETTERS ::::::::::::: //

    /**
     * @notice Retrieves the current status of the contract
     * @dev The value of workflowStatus is returned
     */
    function getWorkflowStatus() external view returns (WorkflowStatus status) {
        return workflowStatus;
    }

    /**
     * @notice Retrieves all the proposals of the contract
     * @dev The value of proposalsArray is returned
     */
    function getProposals() external view returns(Proposal[] memory) {
        return proposalsArray;
    }

    /**
     * @notice Find the voter by his address. Voters only can execute this function
     * @dev This returns the structure of the voter chosen by his address, we can then know if he is registered, if he has voted and the proposal voted
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /**
     * @notice Retrieves a proposal by its id
     * @dev Uses the id of a proposal to retrieve a proposal along with its description and number of votes
     */
    function getOneProposal(uint _id) external view returns (Proposal memory) {
        return proposalsArray[_id];
    }

    /**
     * @notice Retrieves winners if there is a draw after the votes are tallied
     * @dev If the voting status is tallied then we can get the winners in case of a draw
     */
    function getWinners() external view returns (Proposal[] memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, 'Votes are not tallied yet');
        return winningProposals;
    }

    /**
     * @notice Retrieves the winner of the vote
     * @dev If the voting status is tallied then we can get the winner, if multiple winners it should not be used
     */
    function getWinner() external view returns (Proposal memory) {
        require(workflowStatus == WorkflowStatus.VotesTallied, 'Votes are not tallied yet');
        return proposalsArray[winningProposalID];
    }
 
    // ::::::::::::: REGISTRATION ::::::::::::: // 

    /**
     * @notice The owner can add a voter
     * @dev If the workflow status is RegisteringVoters, and the id of the voter passed in parameter is not already registered
     */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /**
     * @notice Adds a proposition with a description, only voters can use this function
     * @dev The voter must submit a description for his proposal, the status must be ProposalsRegistrationStarted
     */
    function addProposal(string memory _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /**
     * @notice Submit a vote by its id, only voters can use this function
     * @dev The voter must submit a vote for his favorite proposal, the status must be VotingSessionStarted, the proposal id must exist and the voter can only vote once
     */
    function setVote( uint _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id <= proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /**
     * @notice Go to proposal registration status, only the owner can execute this function
     * @dev The status must be RegisteringVoters, then the status becomes ProposalsRegistrationStarted
     */
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /**
     * @notice End proposal registration, only the owner can execute this function
     * @dev The status must be ProposalsRegistrationStarted, then the status becomes ProposalsRegistrationEnded
     */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /**
     * @notice Go to voting session status, only the owner can execute this function
     * @dev The status must be ProposalsRegistrationEnded, then the status becomes VotingSessionStarted
     */
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /**
     * @notice End voting session, only the owner can execute this function
     * @dev The status must be VotingSessionStarted, then the status becomes VotingSessionEnded
     */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    /**
     * @notice Tally the votes in case of a draw, only the owner can execute this function
     * @dev The status must be VotingSessionEnded, then the status becomes VotesTallied
     */
    function tallyVotesDraw() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
        uint highestCount;
        uint[5] memory winners; // egalite entre 5 proposals max
        uint nbWinners;
        for (uint i = 0; i < proposalsArray.length; i++) {
            if (nbWinners<5){
                if (proposalsArray[i].voteCount == highestCount) {
                    winners[nbWinners]=i;
                    nbWinners++;
                }
                if (proposalsArray[i].voteCount > highestCount) {
                    delete winners;
                    winners[0]= i;
                    highestCount = proposalsArray[i].voteCount;
                    nbWinners=1;
                }
            }
        }
        for(uint j=0;j<nbWinners;j++){
            winningProposalsID.push(winners[j]);
            winningProposals.push(proposalsArray[winners[j]]);
        }
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /**
     * @notice Tally the votes, only the owner can execute this function
     * @dev The status must be VotingSessionEnded, then the status becomes VotesTallied
     */
    function tallyVotes() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
        uint _winningProposalId;
        for (uint256 p = 0; p < proposalsArray.length; p++) {
            if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
                _winningProposalId = p;
            }
        }
        winningProposalID = _winningProposalId;
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }
}