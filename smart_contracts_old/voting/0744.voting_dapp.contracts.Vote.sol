// SPDX-License-Identifier: Academic Free License v1.2
//Solidity Version
pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

contract Voting {
        
    address public responisbleOfElection;
    address[] public votersList;


    // Dats de début et de fin les élections
    // définis par le responsable des élections
    uint electionStartDate;
    uint electionEndDate;

    struct Candidate {
        string name; // pour faciliter nous prenons le type string, mais bytes32 serait mieux car moins coûteux
        uint voteCount; // nombre de votes accumulés
    }

    // We'll set that a voter can only have 
    // one additional vote delegated to him
    struct Voter {
        uint weight; // nombre de votes possible (s'accumule avec la délégation de vote)
        bool voted;  // if true, that person already voted
        address delegate; // personne à qui on délègue le vote
        uint vote;   // index of the voted candidate
        uint voteDelagated; // le vote de la personne qui a défini ce voteur comme son délégué
    }

    /*function addVoter () public {
        Voter memory newVoter = Voter(1, false, address(0), -1);
    }*/

    mapping(address => Voter) public voters;

    Candidate[] public candidates;
//    Voter[] public electoralRoll; // liste des électeurs définie par le responsable des élections

    constructor(string[] memory candidateNames, address[] memory electoralRoll, uint startDate, uint endDate) {
        responisbleOfElection = msg.sender;
        voters[responisbleOfElection].weight = 1;
        
        require(
            startDate < endDate, 
            "La date de debut doit etre avant la date de fin des elections"
            );
        electionStartDate = startDate;
        electionEndDate = endDate;

        // remplissage de la liste des candidats définis par le Responsable des élections
        for (uint i = 0; i < candidateNames.length; i++) {
            // 'Candidate({...})' creates a temporary
            // Candidate object and 'candidates.push(...)'
            // appends it to the end of 'candidates'.
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }

        // Donner le droit de vote pour les électeurs
        require(
            msg.sender == responisbleOfElection,
            "Only responisbleOfElection can give right to vote."
        );
        for (uint i = 0; i < electoralRoll.length; i++) {
            voters[electoralRoll[i]].weight = 1;
            voters[electoralRoll[i]].voted = false;
            votersList.push(electoralRoll[i]); // sert à remplir la votersList pour facilier son get en UI
        }
    }
       
    function  isVotingOpen () public view{
        require(electionStartDate <= block.timestamp, "Voting hasn't started yet");
        require(electionEndDate >= block.timestamp, "Voting has ended");
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     * chaque 
     */
    function delegate(address to, uint vote_) public {
        isVotingOpen(); // cette vérification est ajoutée ici car cette fonction peut modifier le voteCount
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        require(sender.weight < 2, "You already have a delegated vote"); // Ne pas déléguer de vote 

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        //sender.weight = 0; // n'a plus de vote possible
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            //candidates[delegate_.vote].voteCount += sender.weight;
            candidates[vote_].voteCount += 1; // nous prenons le vote passé en para par la personne qui délègue son vote
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += 1; // donner au délégué un vote de plus
            delegate_.voteDelagated = vote_; // Donner le choix du vote au délégué
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to candidate 'candidates[candidate].name'.
     * @param candidate index of candidate in the candidates array
     */
    function vote(uint candidate) public {
        isVotingOpen();
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidate;
        

        // If 'candidate' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.

        // Si le voteur a un weight de 1 : donc n'a pas vote délégué on incrémente le voteCount de son vote, 
        // sinon on l'incrémente lui ainsi que celui du vote qu'on lui délégué
        if(sender.weight <= 1){
            candidates[candidate].voteCount += 1;
        } else { // une fois ce voteur vote, nous ajoutons son vote ainsi que celui qu'on lui délégué
            candidates[candidate].voteCount += 1;
            candidates[sender.voteDelagated].voteCount += 1;
        }
        
    }

    /** 
     * @dev Computes the winning candidate taking all previous votes into account.
     * @return winner index of winning candidate in the candidates array
     */
    function winningCandidate() public view
            returns (uint winner)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winner = p;
            }
        }
    }

    /** 
     * @dev Calls winningCandidate() function to get the index of the winner contained in the candidates array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = candidates[winningCandidate()].name;
    }

    // Nombre de votes obtenu par le gagnat
    function winnerVoteCount () public view
        returns (uint winnerVoteCount_)
        {
            winnerVoteCount_ = candidates[winningCandidate()].voteCount;
        }

    function showWeight () public view
        returns (uint weight_)
        {
            Voter storage sender = voters[msg.sender];
            weight_ = sender.weight;
        }
    
    // nombre de votes par candidat
    function showVotePerCandidate (uint candidate_) public view
        returns (uint voteCount_)
        {
            voteCount_ = candidates[candidate_].voteCount;
        }
    // return the Start date of the contract    
    function getStartDate () public view returns (uint)
        {
            return electionStartDate;
        }
    // returns the end date of the contract
    function getEndDate () public view returns (uint)
        {
            return electionEndDate;
        }
    // returns the list of the eligible voters
    function getVoters() public view returns (address [] memory){
            return votersList;
        }

 
}


