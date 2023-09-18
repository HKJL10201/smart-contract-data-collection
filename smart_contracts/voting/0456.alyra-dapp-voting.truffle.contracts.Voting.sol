// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    uint256 winningProposalID;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // ::::::::::::: STATE ::::::::::::: //

    WorkflowStatus public workflowStatus;
    Proposal[] proposalsArray;
    mapping(address => Voter) voters;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    modifier onlyVoters() {
        require(voters[msg.sender].isRegistered, "You're not a voter");
        _;
    }

    // ::::::::::::: CONSTRUCTOR ::::::::::::: //

    /**
     * @dev Initialise le contrat en créant le premier votant (le propriétaire du contrat).
     * @notice Comme précisé dans la consigne, il faut que le propriétaire du contrat puisse
     * aussi voir la proposition gagnante à la fin du vote (le "tout le monde"):
     * Ceci est une sécurité de la fonction getOneProposal() qui ne peut être appelée que par un votant.
     * Autant donc que le propriétaire du contrat soit aussi votant dès le déploiement du contrat.
     * Je pense aussi que le propriétaire du contrat doit pouvoir voir toutes les propositions, tout
     * comme les autres votants, afin de décider de ne pas avancer dans le workflow si il y a des abus.
     */
    constructor() {
        // add owner as voter
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender);
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /**
     * @dev Récupère les informations d'un votant enregistré.
     * @param _addr Adresse du votant.
     * @notice Cette fonction ne peut être appelée que par un votant.
     * @return Voter Les informations du votant.
     */
    function getVoter(
        address _addr
    ) external view onlyVoters returns (Voter memory) {
        return voters[_addr];
    }

    /**
     * @dev Récupère les informations d'une proposition enregistrée.
     * @param _id Identifiant de la proposition.
     * @notice Cette fonction ne peut être appelée que par un votant.
     * @return Proposal Les informations de la proposition.
     */

    function getOneProposal(
        uint256 _id
    ) external view onlyVoters returns (Proposal memory) {
        return proposalsArray[_id];
    }

    // :::::::::::::ENREGISTREMENT DES VOTANTS ::::::::::::: //

    /**
     * @dev Ajoute un votant à la liste des votants.
     * @param _addr Adresse du votant à ajouter.
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat.
     */

    function addVoter(address _addr) external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Voters registration is not open yet"
        );
        require(voters[_addr].isRegistered != true, "Already registered");

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: ENREGISTREMENT DES PROPOSITIONS ::::::::::::: //

    /**
     * @dev Ajoute une proposition à la liste des propositions.
     * @param _desc Description de la proposition à ajouter.
     * @notice Cette fonction ne peut être appelée que par un votant.
     */
    function addProposal(string calldata _desc) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Proposals are not allowed yet"
        );
        require(
            keccak256(abi.encode(_desc)) != keccak256(abi.encode("")),
            "Vous ne pouvez pas ne rien proposer"
        ); // facultatif
        // voir que desc est different des autres

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length - 1);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /**
     * @dev Permet à un votant de voter pour une proposition.
     * @param _proposalId L'ID de la proposition pour laquelle le votant veut voter.
     * @notice Le votant doit avoir le statut de votant et la session de vote doit être ouverte.
     * @notice Le votant ne peut voter qu'une seule fois et doit voter pour une proposition existante.
     * @notice Cette fonction met à jour le vote du votant, le vote de la proposition, et met à jour l'ID
     * de la proposition gagnante à chaque vote: ceci afin d'éviter de boucler sur proposalsArray lors de tallyvotes()
     * pour se prémunir de l'attaque DoS Gas Limit.
     */
    function setVote(uint256 _proposalId) external onlyVoters {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        require(voters[msg.sender].hasVoted != true, "You have already voted");
        require(_proposalId < proposalsArray.length, "Proposal not found");

        voters[msg.sender].votedProposalId = _proposalId;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_proposalId].voteCount++;

        if (
            proposalsArray[_proposalId].voteCount >
            proposalsArray[winningProposalID].voteCount
        ) {
            winningProposalID = _proposalId;
        }

        emit Voted(msg.sender, _proposalId);
    }

    // ::::::::::::: SESSION D'ENREGISTREMENT DES PROPOSITIONS ::::::::::::: //

    /**
     * @dev Démarre l'enregistrement des propositions.
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat.
     * @notice Le statut de workflow doit être "enregistrement des votants".
     * @notice Cette fonction crée une proposition initiale avec la description "GENESIS".
     */
    function startProposalsRegistering() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.RegisteringVoters,
            "Registering proposals cant be started now"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);

        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
    }

    /**
     * @dev Termine l'enregistrement des propositions.
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat.
     * @notice Le statut de workflow doit être "enregistrement des propositions".
     */
    function endProposalsRegistering() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
            "Registering proposals havent started yet"
        );
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    // ::::::::::::: SESSION DE VOTE ::::::::::::: //

    /**
     * @dev Démarre la session de vote.
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat.
     * @notice Le statut de workflow doit être "enregistrement des propositions terminé".
     */
    function startVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
            "Registering proposals phase is not finished"
        );
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
    }

    /**
     * @dev Termine la session de vote et calcule le gagnant.
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat.
     * @notice Le statut de workflow doit être "session de vote commencée".
     * @notice Le gagnant est la proposition qui a obtenu le plus de votes.
     */
    function endVotingSession() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionStarted,
            "Voting session havent started yet"
        );
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
    }

    // ::::::::::::: DECOMPTE DES VOIX ::::::::::::: //

    /**
     * @dev Cette fonction stoppe la session de vote.
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat
     * @notice Le statut de workflow doit être "session de vote terminée"
     * @notice Cette étape rend possible la consultation de winningProposalID pour obtenir l'ID de la proposition gagnante.
     */
    function tallyVotes() external onlyOwner {
        require(
            workflowStatus == WorkflowStatus.VotingSessionEnded,
            "Current status is not voting session ended"
        );
        workflowStatus = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
    }
    /** 
     * @dev Retourne la proposition gagnante
     * @notice Cette fonction ne peut être appelée que par le propriétaire du contrat ou un Voter 
     * @return Id de la proposition
    */
    function getWinningProposalID()
        external
        view
        returns (uint256 )
    {
        require(owner() == msg.sender || voters[msg.sender].isRegistered, "you are neither the owner nor a voter");   
        require(workflowStatus == WorkflowStatus.VotesTallied, "Current status is not tallied vote");   
        return winningProposalID;
    }
}
