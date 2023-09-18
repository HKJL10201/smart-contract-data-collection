// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title A Voting system contract
/// @author Cyril C
/// @notice You can use this contract to use a voting system on the blockchain Ethereum
/// @dev This contract extends the Ownable contract from OpenZeppelin
contract Voting is Ownable {

    uint8 public winningProposalID;
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum  WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping (address => Voter) voters;


    event VoterRegistered(address _voterAddress); 
    event WorkflowStatusChange(WorkflowStatus _previousStatus, WorkflowStatus _newStatus);
    event ProposalRegistered(uint _proposalId);
    event Voted (address _voter, uint _proposalId);

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    

    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Use this function to retreive the voter's datas
    /// @dev Retreive the datas from the voters mapping
    /// @param _addr The voter's address
    /// @return The voter's datas
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    
    /// @notice Use this function to retreive the proposal's datas
    /// @dev Retreive the datas from the proposal array
    /// @param _id The proposal's id
    /// @return The proposal's datas
    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
    // ::::::::::::: REGISTRATION ::::::::::::: //

    /// @notice Use this function to add a voter on the whitelist
    /// @dev Add a voter on the voters mapping. Can be executed only by the owner of the contract. Emit an event  
    /// @param _addr The voter's address
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

    // ::::::::::::: PROPOSAL ::::::::::::: // 

    /// @notice Use this function to add a proposal
    /// @dev Add a proposal on the proposal array.
    /// @dev Can be executed only by a voter of the whitelist.
    /// @dev We limit the length of the proposals array to avoid DoS gas limit attack
    /// @dev Emit an event
    /// @param _desc The proposal's description
    function addProposal(string memory _desc) external onlyVoters {
        // 
        require(proposalsArray.length <= 10, "Proposals list is full");
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /// @notice Use this function to vote for an existing proposal
    /// @dev Incremente the number of vote for the given proposal.
    /// @dev Can only be executed by a voter of the whitelist.
    /// @dev We calcule the winningProposalID here to avoid the Dos Gas Limit attack within the talliedVote function
    /// @dev Emit an event
    /// @param _id The proposal's id
    function setVote(uint8 _id) external onlyVoters {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        require(voters[msg.sender].hasVoted != true, 'You have already voted');
        require(_id < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        // On déplace la calcul du gagnant au moment du vote 
        if (proposalsArray[_id].voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = _id;
        }

        emit Voted(msg.sender, _id);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice Use this function to start the proposal registering phase
    /// @dev Change the WorkflowStatus to RegisteringVoters. Emit an event
    function startProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender);
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        emit ProposalRegistered(0);
        
    }

    /// @notice Use this function to end the proposal registering phase
    /// @dev Change the WorkflowStatus to ProposalsRegistrationEnded. Emit an event
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    /// @notice Use this function to start the voting session phase
    /// @dev Change the WorkflowStatus to VotingSessionStarted. Emit an event
    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Use this function to end the voting session phase
    /// @dev Change the WorkflowStatus to VotingSessionEnded. Emit an event
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    // ===== SECURITE =====
    // La fonction n'est plus a utiliser. On a déplacer le calcul du gagnant dans la fonction de vote
    // Plus de souci de boucle for et de potentiel DoS Gas Limit
    // Pour recup l'id du gagnant on utilise le getter winningProposalID
    // ====================
//    function tallyVotes() external onlyOwner {
//        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended");
//        uint8 _winningProposalId;
//       for (uint8 p = 0; p < proposalsArray.length; p++) {
//            if (proposalsArray[p].voteCount > proposalsArray[_winningProposalId].voteCount) {
//                _winningProposalId = p;
//           }
//        }
//        winningProposalID = _winningProposalId;
       
//        workflowStatus = WorkflowStatus.VotesTallied;
//        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
//     }
}