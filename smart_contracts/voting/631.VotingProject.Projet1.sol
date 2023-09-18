// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    // Création de la structure de la whitelist.
    struct Whitelist {
        address user;
        bool isWhitelisted;
        bool hasProposed;
    }

    // Création de la structure des inscrits (voteurs).
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // Création de la structure des propositions.
    struct Proposal {
        string description;
        uint voteCount;
    }

    // Différents mappings respectivement déclarée aux structs.
    mapping(address => Whitelist) whitelisteds;
    mapping(address => Voter) voters;
    mapping(address => Proposal) proposals;

    // Mapping d'un nombre vers les propositions pour le voteCount.
    mapping(uint => Proposal) proposalsUint;

    // Tableau pour permettre de récupérer les fonctions dans un tableau.
    address[] whitelistedsArray;
    string[] proposalsStringArray;
    Proposal[] proposalsArray;

    // Différents états du smart-contracts
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public defaultStatus;

    // Différents évènements
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    // Permet à l'Owner d'ajouter à la main les whitelistés.
    function a_addWhitelist(address _user) public onlyOwner {
        whitelisteds[_user].user = _user; // Ajout d'une adresse à la whitelist.
        whitelisteds[_user].isWhitelisted = true; // Notification de l'inscription à la whitelist.
        whitelistedsArray.push(_user); 
    }

    // Permet de savoir qui est whitelisté.
    function b_getWhitelist() public view returns(address[] memory){

        address[] memory _adresses = new address[](whitelistedsArray.length);

        for (uint i = 0; i < whitelistedsArray.length; i++) {
            _adresses[i] = whitelistedsArray[i];
        }
        return whitelistedsArray;
    }


    // Fonctions qui permettent de commencer et stopper les 2 sessions.
    bool startAndStopProposal = false;
    bool startAndStopVote = false;

    function c_startProposal() public onlyOwner {
        startAndStopProposal = true;
        defaultStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function e_stopProposal() public onlyOwner {
        startAndStopProposal = false;
        defaultStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function h_startVote() public onlyOwner {
        startAndStopVote = true;
        defaultStatus = WorkflowStatus.VotingSessionStarted;
    }

    function j_stopVote() public onlyOwner {
        defaultStatus = WorkflowStatus.VotingSessionEnded;
        startAndStopVote = false;
    }


    /*
    function isWhitelist(address _user) public view returns(bool){
        if(whitelisteds[_user].hasProposed == true){
            return true;
        }
        return false;
    } */

    // Début de la session de propositions pour les whitelistés.
    function d_propositionSession(string memory _description) public {
        require(startAndStopProposal == true, unicode"La session de proposition n'est pas active."); // Condition qui vérifie si la session de proposition est active.
        require(whitelisteds[msg.sender].isWhitelisted == true && whitelisteds[msg.sender].hasProposed == false, unicode"Vous n'êtes pas autorisé à créer une proposition."); // Condition qui vérifie si msg.sender est whitelisté et n'a jamais proposé de proposition.
        
        whitelisteds[msg.sender].hasProposed = true; // msg.sender a déjà fait une proposition.
        proposalsStringArray.push(_description); // Récupérer la description de la proposition dans un tableau pour getProposals().
        uint _voteCount; 
        Proposal memory thisProposal = Proposal(_description, _voteCount);
        proposalsArray.push(thisProposal); // Ajouter la proposition au tableau de proposition pour pouvoir le parcourir ensuite
        emit ProposalRegistered(_voteCount);
    }

    // Permet de récupérer les propositions.
    function f_getProposals() public view returns(string[] memory){

        // Créer un tableau pour stocker les propositions .
        string[] memory _proposals = new string[](proposalsStringArray.length);

        // Remplir le tableau avec les propositions.
        for (uint i = 0; i < proposalsStringArray.length; i++) {
            _proposals[i] = proposalsStringArray[i];
        }
        return proposalsStringArray;
    }


    //Permet de récupérer la proposition d'une adresse
    /*function getPropositionOfAddress(address _user) public view returns(string memory){
        if(voters[msg.sender].isRegistered != true){ 
            if(whitelisteds[msg.sender].isWhitelisted != true){ // Vérifie si l'utilisateur est inscrit en tant que voter OU est whitelisté
                revert NotRegisteredAtVoter();
            }
        }
        return proposals[_user].description;
    }*/

    // Fonction qui permet aux utilisateurs de s'inscrire en tant que voters.
    function g_votersInscription(address _user) public {
        require(msg.sender == _user || msg.sender == owner(), unicode"Vous n'êtes pas autorisé.");
        voters[_user].isRegistered = true;
        emit VoterRegistered(_user);

        defaultStatus = WorkflowStatus.RegisteringVoters;

    }
    
    // Permet de démarrer la session de vote en rentrant l'adresse qui nous intéresse.
    function i_voteSession(uint _proposalId) public {
        require(startAndStopProposal == false, unicode"La session de proposition n'est pas terminée."); // Condition qui vérifie si les propositions sont finis.
        require(startAndStopVote == true, unicode"La session de vote n'est pas active."); // Condition qui vérfiie si la session a bien commencé.
        require(voters[msg.sender].isRegistered == true || whitelisteds[msg.sender].isWhitelisted == true, unicode"Vous n'êtes pas autorisé à voté."); // Conditions qui vérifie si le voteur est inscrit ou whitelisté.
        require(voters[msg.sender].hasVoted == false, unicode"Vous avez déjà voté !"); // Condition qui vérifie si le voteur a déjà voté.
        voters[msg.sender].hasVoted = true; // Le voteur a déjà voté.
        proposalsUint[_proposalId].voteCount++; // Incrémentation du nombre de vote par proposition.
        proposalsArray[_proposalId].voteCount++; // Incrémentation du voteCount pour la fonction getWinner.
        voters[msg.sender].votedProposalId = _proposalId; // Actualiser la proposition du voteur.
        emit Voted(msg.sender, _proposalId);
    }

    // Récupérer le nombre de vote que possède une proposition
    function k_getCount(uint _proposalId) public returns(uint){
        defaultStatus = WorkflowStatus.VotesTallied;
        return proposalsUint[_proposalId].voteCount;
    }

    // Fonction qui retournera la proposition gagnante
    function m_getWinner() public view returns(string memory){
            require(startAndStopVote == false, unicode"La session de vote n'est pas terminée."); // Condition qui vérifie si les votes sont finis.

            Proposal memory winProposal = proposalsArray[0]; // Création de la proposition gagnante et définie comme la première.

            // Boucle qui parcours le tableau de proposition et de vérifier si la proposition gagnante (ci-dessus) a plus de vote que la proposition qui suit dans le tableau.
            for(uint i = 1; i < proposalsArray.length; i++){
                if(proposalsArray[i].voteCount > winProposal.voteCount){ // Si la condition d'après (en i) est plus grande que la proposition gagnante définie ci-dessus.
                    winProposal = proposalsArray[i]; // Alors du change la proposition gagnante à la nouvelle proposition (en i) qui possède le plus de votes.
                }
            }
            return winProposal.description; // Retourne moi uniquement la description de la proposition gagnante
            // Si on veut récupérer le voteCount de la proposition gagnante, on aurait retiré le .descriptin et décris que la valeur
            // que l'on veut retourner dans la fonction est "Proposal memory").
    }
}

// J'ai nommé les différentes fonctions avec des lettres devant pour avoir un ordre des fonctions a exécuter
