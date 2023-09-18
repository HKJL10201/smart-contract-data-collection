pragma solidity ^0.4.20;

// Smart contract for a voting system
contract VotingSystem{

    // Voter struct, representing each voter, where:
    // - alreadyVoted is a flag that is active if this voter has already voted
    // - vote is the index of this voter's voted candidate
    struct Voter{
        bool alreadyVoted;
        uint vote;
    }

    // Candidate struct, representing each vote option, where:
    // - name represents each candidate's name
    // - votes is the count of the votes each candidate has received
    struct Candidate{
        bytes32 name;
        uint votes;
    }

    // Variables that will store all voters and candidates
    mapping (address => Voter) public voters;
    Candidate[] public candidates;

    // Address that identifies the owner of the voting
    address public owner;

    // Flag that allows to know if voting is still available
    bool public isOpen;

    // Constructor function, that receives an array with the name
    // of each candidate, and creates every necessary slot in "candidates" array
    // NOTE: The user that creates the voting becomes the owner of the voting,
    // thus, the only one able to close it
    function VotingSystem (bytes32[] candidatesNames) public {
        owner = msg.sender;
        isOpen = true;
        for (uint i=0; i < candidatesNames.length; ++i){
            // The candidate is included in the array
            candidates.push(Candidate({
                name: candidatesNames[i],
                votes: 0
            }));
        }
    }

    // Voting function, can only be called once per voter
    function Vote (uint candidateVote) public {
        // The first requirement is that the voting has to be open
        require(isOpen);

        // Then the currentVoter has to be located, and it is mandatory
        // to check if they have already voted
        Voter storage currentVoter = voters[msg.sender];
        require(!currentVoter.alreadyVoted);

        // If they have not already voted, the flag is switched to true,
        // and then the vote is registered
        currentVoter.vote = candidateVote;
        currentVoter.alreadyVoted = true;

        // And of course, the vote is added to the candidate's count
        candidates[candidateVote].votes++;
    }

    function TotalVotesFor(uint candidate) constant returns (uint) {
        return candidates[candidate].votes;
    }

    // Voting closing function, can only be called by the owner, and automatically sets the
    // isOpen flag to false
    function CloseVoting () public {
        require((msg.sender == owner) && isOpen);
        isOpen = false;
    }

    // A function able to count votes and announce which candidate is the winner
    function GetWinner () constant returns (bytes32){
        require(!isOpen);
        uint maxAmountOfVotes = 0;
        uint winnerCandidate = 0;
        for (uint i=0; i < candidates.length; ++i){
            if (candidates[i].votes > maxAmountOfVotes){
                maxAmountOfVotes = candidates[i].votes;
                winnerCandidate = i;
            }
        }
        return candidates[winnerCandidate].name;
    }
}
