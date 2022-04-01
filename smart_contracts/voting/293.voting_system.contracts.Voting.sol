// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.11;
import 'openzeppelin-solidity/contracts/access/Ownable.sol';
/**
 * @title Voting
 * @dev Smart contract de vote
 */
contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    uint public winningProposalId;

    mapping(address => bool) public whitelist;
    mapping(address => Voter) public voters;
    mapping(uint8 => WorkflowStatus) private state;

    WorkflowStatus public votingStatus;
    Proposal[] public proposals;

    /**
     * @dev Vérifie si l'utilisateur est enregistré
     */
    modifier registred {
        require(whitelist[msg.sender] == true, "Non enregistré sur la liste blanche");
        _;
    }

    /**
     * @dev Ajouter un électeur à la liste blanche
     * @param voterAddress Adresse du votant
     */
    function addWhiteList(address voterAddress) external onlyOwner {
        require(!whitelist[voterAddress], "Déjà enregistré");
        whitelist[voterAddress] = true;
        voters[voterAddress] = Voter(true, false, 0);
        emit VoterRegistered(voterAddress);
    }
    /**
     * @dev passe à l'étape suivante du processus de propositions/vote
     */
    function nextStep() external onlyOwner {
        votingStatus = WorkflowStatus(uint(votingStatus)+1);
        emit WorkflowStatusChange(WorkflowStatus(uint(votingStatus)-1), WorkflowStatus(uint(votingStatus)));
        if (votingStatus == WorkflowStatus(uint(1))) { startProposalsRegistration();}
        if (votingStatus == WorkflowStatus(uint(2))) { closeProposalsRegistration();}
        if (votingStatus == WorkflowStatus(uint(3))) { startVotingSession();}
        if (votingStatus == WorkflowStatus(uint(4))) { closeVotingSession();}
        if (votingStatus == WorkflowStatus(uint(5))) { getWinningProposal();}
    }
    /**
     * @dev Démarrer la session d'enregistrement des propositions
     */
    function startProposalsRegistration() private onlyOwner {
        addProposal("Abstentation");
        emit ProposalsRegistrationStarted();

    }

    /**
     * @dev Ajouter une proposition
     * @param description Description de la proposition
     */
    function addProposal(string memory description) public registred {
        require(votingStatus == WorkflowStatus.ProposalsRegistrationStarted, "impossible de faire des propositions");
        proposals.push(Proposal(description,0));
        uint id = proposals.length-1;
        emit ProposalRegistered(id);
    }
    /**
     * @dev Mettre fin à la session d'enregistrement des propositions
     */
    function closeProposalsRegistration() private onlyOwner {
        emit ProposalsRegistrationEnded();
    }

    /**
     * @dev Démarrer la session de vote
     */
    function startVotingSession() private onlyOwner {
        emit VotingSessionStarted();

    }

    /**
     * @dev Voter pour une proposition
     * @param _proposalId ID de la proposition
     */
    function addVote(uint _proposalId) external registred {
        require(votingStatus == WorkflowStatus.VotingSessionStarted, "impossible de voter");
        require(voters[msg.sender].hasVoted == false, "Déjà voté");
        proposals[_proposalId].voteCount++;
        voters[msg.sender] = Voter(true, true, _proposalId);
        emit Voted (msg.sender, _proposalId);
    }

    /**
     * @dev Mettre fin à la session de vote
     */
    function closeVotingSession() private onlyOwner {
        emit VotingSessionEnded();
    }

    /**
     * @dev Comptabilise les votes pour récupérer la proposition gagnante
     * @return _proposalId ID de la proposition gagnante
     */
    function getWinningProposal() private onlyOwner returns (uint _proposalId) {
        uint winnerVoteCount = 0;
        uint challenger = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winnerVoteCount) {
                winnerVoteCount = proposals[i].voteCount;
                _proposalId = i;
            } else if (proposals[i].voteCount == winnerVoteCount) {
                challenger = i;
            }
        }
        winningProposalId = _proposalId;
        if(winnerVoteCount == proposals[challenger].voteCount) {
             winningProposalId = 0;
        }
        emit VotesTallied();
        return winningProposalId;
    }

    /**
     * @dev Récupère les informations concernant la proposition gagnante
     * @return description Description de la proposition
     * @return voteCount Nombre de vote 
     */
    function getWinningInfo() public view returns (string memory description, uint voteCount) {
        require(winningProposalId != 0, "Aucune proposition gagnante");
        return (proposals[winningProposalId].description, proposals[winningProposalId].voteCount);
    }

    /**
     * @dev Récupère le nombre de propositions
     * @return uint Nombre de propositions
    */
    function getProposalCount() public view returns(uint) {
        return proposals.length;
    }
}
