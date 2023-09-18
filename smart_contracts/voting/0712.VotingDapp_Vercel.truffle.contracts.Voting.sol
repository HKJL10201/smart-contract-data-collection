// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/// @title  Smart Contract Dédié a la DApp de Vote Decentralisée
/// @author @ielboulo @ivxry
/// @notice Le propriétaire du contrat peut démarrer et terminer les différentes étapes du processus de vote :
///         Enregistrement des participants
///         Enregistrement des propositions
///         Session de vote
///         Décompte des votes
/// @dev    Un contrat intelligent pour effectuer un vote avec des propositions faites par les participants au vote.
///         Les participants peuvent être enregistrés par le propriétaire du contrat et ne peuvent voter que pour une proposition.
///
///         Les propositions peuvent être enregistrées par les participants enregistrés pendant la session de proposition.
///         
///         Le contrat recolte les votes reçus et soumet la proposition gagnante en fonction du nombre de votes.
///         
///         Le contrat émet également des événements pour différentes actions et changements d'état importants lors des différentes étapes.

contract Voting is Ownable {

    uint public winningProposalID;
    
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


    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);


    /**
    @dev Constructeur : crée un nouveau contrat de vote et ajoute l'owner du contrat sur la liste des participants.
    */
    constructor(){
        // we assume that the admin has also the right to vote 
        voters[msg.sender] = Voter(true, false, 0);
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender); 

    }

    /**
    @dev Vérifie si l'addresse de l'appelant est enregistré comme participant.
    */
    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }
    
    // on peut faire un modifier pour les états 

    // Appel de la liste des Addresses admises a voter
    /**
    @dev Récupère les détails d'un participant enregistré.
    @param _addr Adresse Ethereum du participant.
    @return Voter : le struct Voter renvoie les détails du participant.
     */
    function getVoter(address _addr) external onlyVoters view returns (Voter memory) {
        return voters[_addr];
    }
    

    /**
    @dev Récupère les détails d'une proposition ddepuis la mémoire du contrat.
    @param _id Identifiant de la proposition par son index dans l'Array.
    @return Proposal : la struct Proposal avec les détails de la proposition.
    */

    function getOneProposal(uint _id) external onlyVoters view returns (Proposal memory) {
        return proposalsArray[_id];
    }

 
        /**
        @dev Ajout par l'Owner du contrat, d'un participant sur la liste des participants.
        @param _addr Adresse Ethereum du participant à ajouter.
        */
    function addVoter(address _addr) external onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Voters registration is not open yet');
        require(voters[_addr].isRegistered != true, 'Already registered');
    
        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }
 

        /**
        @dev Ajoute une nouvelle proposition à l'Array Proposal.
        @param _desc Contenu de la proposition.
        */
    function addProposal(string calldata _desc) external onlyVoters {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Proposals are not allowed yet');
        require(keccak256(abi.encode(_desc)) != keccak256(abi.encode("")), 'Vous ne pouvez pas ne rien proposer'); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length-1);
    }

        /**
        @dev Ajout du vote du participant pour une proposition donnée et vérification de son droit de vote au préalable.
        @param proposalId Identifiant de la proposition pour laquelle le participant vote.
        */
    function setVote(uint proposalId) public {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting Session not started yet');
        require(voters[msg.sender].isRegistered, "You are not allowed to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(proposalId < proposalsArray.length, 'Proposal not found'); // pas obligé, et pas besoin du >0 car uint

        proposalsArray[proposalId].voteCount += 1;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = proposalId;

        if (proposalsArray[proposalId].voteCount > proposalsArray[winningProposalID].voteCount) {
            winningProposalID = proposalId;
        }

        emit Voted(msg.sender, proposalId);
    }


        /**
        @dev Démarre la session d'ajout des propositions.
        */
    function startProposalsRegistering() external onlyOwner {

        require(workflowStatus == WorkflowStatus.RegisteringVoters, 'Registering proposals cant be started now');
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        
        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);
        
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

        /**
        @dev Termine la session d'ajout des propositions.
        */
    function endProposalsRegistering() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, 'Registering proposals havent started yet');
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

        /**
        @dev Démarre la session de vote.
        */

    function startVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, 'Registering proposals phase is not finished');
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

        /**
        @dev Termine la session de vote.
        */
    function endVotingSession() external onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, 'Voting session havent started yet');
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

        /**
        @dev Cloture de la session de comptabilisation de votes pour permettre le calcul des résultats par la fonction setVote.
        */

   function tallyVotes() external onlyOwner {
       require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Current status is not voting session ended"); 

       workflowStatus = WorkflowStatus.VotesTallied;
       // Le calcul du winner a été fait dans setVote() : pour éviter d'utiliser une boucle "for"
       
       emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    
}
