// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17; 
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting Decentralized Application 
/// @author Güven Gür
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without side effects

contract Voting is Ownable {

    /* ----- VARIABLES ----- */

    /// @custom:Voter Struct for Voter: contains all the informations on a voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
        /// @custom:sentProposal : To prevent DOS Gas Limit, the number of sent proposal by the voter is registered to limit it 
        uint sentProposal; 
    }

    /// @custom:Proposal Struct for proposal: contains a description and vote counts 
    struct Proposal {
        string description;
        uint voteCount;
    }   

    /// @notice Array of variable with a Proposal struct, stores the proposals
    Proposal[] proposals; 
    
    /// @custom:whitelist Mapping which for each input returns a Voter struct
    mapping (address => Voter) public whitelist; 

    /// @custom:WorkFlowStatus : Enumeration of the different status of the voting session
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    /// @notice State variable containing differents possibles status
    WorkflowStatus public state; 

    /// @notice State variable which registers the index of the current status
    uint8 statusValue; 

    /* ----- EVENTS ----- */ 

    /// @notice Registers the wallet address of added voter
    /// @param voterAddress Wallet address of added voter
    event VoterRegistered(address voterAddress); 

    /// @notice Registers the previous status of the work flow and the new one
    /// @param previousStatus Previous status of the workflow
    /// @param newStatus New status of the workflow
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    /// @notice Registers the Id of each proposal added
    /// @param proposalId Index of the proposal in the array
    event ProposalRegistered(uint proposalId);
    
    /// @notice Registers a event when a voter votes for a proposal 
    /// @param voter Wallet address of the voter
    /// @param proposalId Index of the proposal voted by the voter
    event Voted (address voter, uint proposalId);


    /* ----- CONSTRUCTOR -----*/

    /// @custom:constructor Allows directly the creator of the contract as a voter
    constructor() {
        whitelist[msg.sender].isRegistered = true; 
    }

    /* ----- MODIFIERS ----- */ 

    /// @custom:modifier : Controls if the call of the fonction is done by a authorized voter
    modifier isWhiteListed() {
        require(whitelist[msg.sender].isRegistered, unicode"Vous n'êtes pas autorisé, cela nécessite d'être sur liste blanche");
        _; 
    }

    /// @custom:modifier : Controls if there is proposals registered
    modifier proposalsAreRegistered() {
        require(proposals.length >= 1, unicode"Il n'y a toujours pas de proposition enregistrée");
        _; 
    }

    /// @custom:modifier : Controls if the proposal id specified refers to an existing proposal
    modifier isIndexExisting(uint _proposalId) {
        require (_proposalId < proposals.length, unicode"Le numéro précisé ne correspond à aucune proposition. Veuillez réitérer avec un numéro valide");
        _; 
    }

    /// @custom:modifier : Controls if the voting session started
    modifier isVotingStarted() {
        require(state == WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas encore ouverte");
        _;
    }


    /* ----- FUNCTIONS ----- */
    /*    Functions reserved to the administrator    */ 

    /// @notice Allows the owner of the contract to add voters to the white list, via their ethereum address
    /// @dev Changes the bool hasVoted of the address to true
    /// @param _address Ethereum wallet address of the voter to authorize 
    function authorize(address _address) external onlyOwner {
        require (state == WorkflowStatus.RegisteringVoters, unicode"Il n'est plus possible d'enregistrer d'électeurs sur liste blanche" ); 
        require (!whitelist[_address].isRegistered, unicode"L'adresse est déjà sur liste blanche");

        whitelist[_address].isRegistered = true; 
        emit VoterRegistered(_address); 
    }

    /// @notice Change the current status of the workflow
    /// @dev Only the owner can call this function 
    /// @dev At each call, the enum state is incremented and the statusValue too 
    /// @dev Can't close the proposal registration session if there is less than 2 proposals
    /// @dev Can't close the voting session if there is no vote registered
    function changeStatus() external onlyOwner {

        statusValue++; 

        if (statusValue == 2 && proposals.length < 2 ) {
            revert("Il n'y a pas assez de propositions. Minimum requis : 2");
        }
        else if (statusValue == 4) {
            uint totalOfVotes; 
            totalOfVotes = getTotalOfVotes(); 
            require(totalOfVotes > 0, unicode"Il n'est pas possible de clôturer la session de vote : aucun vote n'a été reçu");  
        }  else if (statusValue > 5) {
            revert (unicode"La session est déjà terminée");
        }

        state = WorkflowStatus(statusValue); 
        emit WorkflowStatusChange(WorkflowStatus(statusValue - 1), WorkflowStatus(statusValue)); 
    } 

    /*    Functions of proposals & voting     */ 
  
    /// @notice Register a new proposal from a voter
    /// @dev Only voters can call this function  
    /// @dev The maximum of proposal by voter is defined with maximumProposal
    /// @param _proposal Description of the proposal 
    function sendProposals(string calldata _proposal) external isWhiteListed {

        uint8 maximumProposal = 3;

        require (state == WorkflowStatus.ProposalsRegistrationStarted, "La session d'enregistrement des propositions n'est pas ouverte" ); 
        require (whitelist[msg.sender].sentProposal < maximumProposal, unicode"Vous avez déjà soumis votre maximum de proposition autorisé");
        
        Proposal memory proposal; 
        proposal.description = _proposal; 
        proposals.push(proposal); 

        whitelist[msg.sender].sentProposal++;
        emit ProposalRegistered(proposals.length - 1);
    }


    /// @notice Register a vote for a proposal 
    /// @dev Only voters can call this function  
    /// @dev This function can only be used one time 
    /// @param _proposalId Id of the favorite proposal
    function voteForProposal(uint _proposalId) external isWhiteListed isIndexExisting(_proposalId) isVotingStarted {
        require(!(whitelist[msg.sender].hasVoted), unicode"Vous avez déjà voté pour votre proposition préférée !");

        proposals[_proposalId].voteCount++; 
        whitelist[msg.sender].hasVoted = true; 
        whitelist[msg.sender].votedProposalId = _proposalId; 
        emit Voted(msg.sender, _proposalId ); 
    }
 

    /*    Functions for information purposes   */ 

    /// @notice Returns the list of all the proposals
    /// @dev Returns an array of struct Proposal
    /// @return Proposal An array of all the proposals
    function getAllProposals() external view isWhiteListed proposalsAreRegistered returns(Proposal[] memory){
        return proposals; 
    }

    /// @notice Returns the description of a proposal by his index
    /// @param _proposalId Id of the desired proposal
    /// @return string The description of the proposal
    function getProposalByIndex(uint _proposalId) external view isWhiteListed proposalsAreRegistered isIndexExisting(_proposalId) returns(string memory) {
        return proposals[_proposalId].description;
    }


    /// @notice Returns the vote count of a specified proposal
    /// @param _proposalId Id of the desired proposal
    /// @return uint The vote count of the proposal
    function getVoteCountByProposal(uint _proposalId) external view isWhiteListed proposalsAreRegistered isIndexExisting(_proposalId) returns(uint) {
        return proposals[_proposalId].voteCount;
    }

    /// @notice Returns the amount of votes registered
    /// @return uint Total of votes registered
    function getTotalOfVotes() public view isWhiteListed isVotingStarted returns(uint) {
        uint totalOfVotes;  

        for(uint i = 0; i <= proposals.length - 1 ; i++) {
            totalOfVotes += proposals[i].voteCount; 
        }   
        return totalOfVotes; 
    }

    /// @notice Return the winning proposal
    /// @dev In case of egality, it's the oldest proposal which wins
    /// @return winningProposalId The Id of the winning proposal 
    function getWinner() public view returns(uint) {  
        require(state >= WorkflowStatus.VotingSessionEnded, unicode"Il faut attendre que les votes soient comptabilisés.");

        uint biggestCount; 
        uint winningProposalId; 
        string memory winningProposal; 

        for(uint i = 0; i <= proposals.length - 1 ; i++) {
            if (biggestCount < proposals[i].voteCount) {
               biggestCount = proposals[i].voteCount;
               winningProposalId = i;
               winningProposal = proposals[i].description; 
           }
        }   
        return (winningProposalId) ;
    }

    /// @notice Allows to know for which proposal on voter has voted
    /// @param _address Ethereum address of the voter desired 
    /// @return votedProposalId The proposal for which the voter has voted  
    function hasVotedFor(address _address) external view isWhiteListed returns(uint, string memory) {
        require(whitelist[_address].isRegistered, unicode"Cet électeur n'a pas pu enregistrer de vote");
        require(whitelist[_address].hasVoted, unicode"Cet électeur n'a pas enregistré de vote");
        return (whitelist[_address].votedProposalId, proposals[whitelist[_address].votedProposalId].description ); 
    }
}