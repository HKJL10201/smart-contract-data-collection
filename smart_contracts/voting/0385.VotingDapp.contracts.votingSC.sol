// pragma solidity ^0.8.0;

// contract Election {
    
//     struct Voter {
//         bool isRegistered;
//         bool hasVoted;
//         uint256 votedFor;
//     }

//     struct Candidate {
//         string name;
//         uint256 voteCount;
//     }

//     // State variables
//     address public admin;
//     mapping(address => Voter) public voters; // address to each 
//     Candidate[] public candidates;
//     uint256 public votingStart;
//     uint256 public votingEnd;
//     uint256 public minimumVotes;
//     bool public isVotingOpen;
//     uint256 public totalVotes;
    

    
//     //Constructor
//    constructor() {
//        // Set the contract deployer as the owner of the contract
//         admin = msg.sender;
//    }

//     // a modifier that only allows a function to be called by the owner
//    modifier onlyOwner() {
//         require(msg.sender == admin, "You are not the owner");

//         _;
//    }

//     // add candidate's name with calculated vote duration timestamp.
//     function contestants(string[] memory candidateNames, uint256 votingStartTime, uint256 votingEndTime, uint256 minVotes) public onlyOwner {
//         // candidates.push(Candidate({name: _name, voteCount: 0}));
//         require(candidateNames.length > 0, "There must be at least one candidate");
//         require(votingStartTime < votingEndTime, "Voting end time must be after voting start time");
//         admin = msg.sender;
//         // Add candidates to the array
//         for (uint256 i = 0; i < candidateNames.length; i++) {
//             candidates.push(Candidate({
//                 name: candidateNames[i],
//                 voteCount: 0
//             }));
//         }
//         votingStart = votingStartTime;
//         votingEnd = votingEndTime;
//         minimumVotes = minVotes;
//         isVotingOpen = true; 

//     }

//     // update the contestant list, incase of addition or removal of a candidate before the voting starts.
//     // function update 
    
//     // Register a voter
//     function registerVoter() public {
//         require(isVotingOpen, "Voting is closed");
//         require(!voters[msg.sender].isRegistered, "Voter has already registered");
//         voters[msg.sender].isRegistered = true;
//     }

//     // Cast a vote for a candidate
//     function castVote(uint256 candidateIndex) public {
//         require(isVotingOpen, "Voting is closed");
//         require(voters[msg.sender].isRegistered, "Voter is not registered");
//         require(!voters[msg.sender].hasVoted, "Voter has already voted");
//         require(candidateIndex < candidates.length, "Invalid candidate index");
//         voters[msg.sender].hasVoted = true;
//         voters[msg.sender].votedFor = candidateIndex;
//         candidates[candidateIndex].voteCount++;
//         totalVotes++;
//     }

//     // End voting
//     function endVoting() public {
//         require(msg.sender == admin, "Only admin can end voting");
//         require(block.timestamp >= votingEnd, "Voting has not ended yet");
//         require(totalVotes >= minimumVotes, "Not enough votes");
//         isVotingOpen = false;
//     }
    
//     // Get the number of candidates
//     function getCandidateCount() public view returns (uint256) {
//         return candidates.length;
//     }

//     // Get the name and vote count of a candidate
//     function getCandidate(uint256 candidateIndex) public view returns (string memory, uint256) {
//         require(candidateIndex < candidates.length, "Invalid candidate index");
//         return (candidates[candidateIndex].name, candidates[candidateIndex].voteCount);
//     }

//     // Check if a voter has already voted
//     function getVoterHasVoted() public view returns (bool) {
//         return voters[msg.sender].hasVoted;
//     }

//     // Get the name of the winning candidate
//     function getWinner() public view returns (string memory) {
//         require(!isVotingOpen, "Voting has not ended yet");
//         uint256 winningVoteCount = 0;
//         uint256 winningCandidateIndex = 0;
//         for (uint256 i = 0; i < candidates.length; i++) {
//             if (candidates[i].voteCount > winningVoteCount) {
//                 winningVoteCount = candidates[i].voteCount;
//                 winningCandidateIndex = i;
//             }
//         }
//         return candidates[winningCandidateIndex].name;
//     }
// }





// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedFor;
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // State variables
    uint256 public listingPrice = 0.0000025 ether;
    address public admin;
    mapping(address => Voter) public voters; // address to each 
    Candidate[] public candidates;
    uint256 public votingStart;
    uint256 public votingEnd;
    uint256 public minimumVotes;
    bool public isVotingOpen;
    uint256 public totalVotes;
    address[] registeredVoters;
    
    // Constructor
   constructor()  {
         admin = msg.sender;
   }

    // add candidate's name with calculated vote duration timestamp.
    function contestants(string[] memory candidateNames, uint256 votingStartTime, uint256 votingEndTime, uint256 minVotes) public  onlyAdmin() {
        // candidates.push(Candidate({name: _name, voteCount: 0}));
        require(candidateNames.length > 0, "There must be at least one candidate");
        require(votingStartTime < votingEndTime, "Voting end time must be after voting start time");
        require(block.timestamp < votingStartTime, "pick a time a little higher than the current time");
        // Add candidates to the array
        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
        votingStart = votingStartTime;
        votingEnd = votingEndTime;
        minimumVotes = minVotes;
        isVotingOpen = true; 
        
    }

    modifier onlyAdmin (){
        require(msg.sender == admin, "Sorry Only Administrator can perform this operation");
        _;
    }

    // update the contestant list, incase of addition or removal of a candidate before the voting starts.
    function addNewCandidate (string memory candidateName) public onlyAdmin(){
        require(!isVotingOpen, "Sorry you cannot add new candidate after voting has started");
       candidates.push(Candidate ({name : candidateName, voteCount : 0})); 
    }
    //reset the candidates 
    function newCandidates(string memory candidateName) public onlyAdmin(){
        delete candidates;
        candidates.push(Candidate ({name : candidateName, voteCount : 0}));
    }
    // Register a voter
    function registerVoter() public {
        require(isVotingOpen, "Voting is closed");
        require(!voters[msg.sender].isRegistered, "Voter has already registered");
        voters[msg.sender].isRegistered = true;
        registeredVoters.push(msg.sender);
    }

    // Cast a vote for a candidate
    function castVote(uint256 candidateIndex) public {
        require(isVotingOpen, "Voting is closed");
        require(voters[msg.sender].isRegistered, "Voter is not registered");
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        require(candidateIndex < candidates.length, "Invalid candidate index");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedFor = candidateIndex;
        candidates[candidateIndex].voteCount++;
        totalVotes++;
    }

    // End voting
    function endVoting() public onlyAdmin(){
        require(block.timestamp >= votingEnd, "Voting has not ended yet");
        require(totalVotes >= minimumVotes, "Not enough votes");
        isVotingOpen = false;
    }
    
    // Get the number of candidates
    function getCandidateCount() public view returns (uint256) {
        return candidates.length;
    }
    function getAdmin() public view returns(address){
       return(admin);
    }
     function getListingPrice() public view returns(uint256){
       return(listingPrice);
    }
    // Get the name and vote count of a candidate
    function getCandidate(uint256 candidateIndex) public view returns (string memory, uint256) {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        return (candidates[candidateIndex].name, candidates[candidateIndex].voteCount);
    }

    // Check if a voter has already voted
    function getVoterHasVoted(address  voter) public view returns (bool) {
        return voters[voter].hasVoted;
    }

    function getVotedFor(address  voter) public view returns (uint256){
        return voters[voter].votedFor;
    }

    function getRegisteredVoters() public view returns (address[] memory){
        return registeredVoters;
    } 
    // Get the name of the winning candidate
    function getWinner() public view returns (string memory) {
        require(!isVotingOpen, "Voting has not ended yet");
        uint256 winningVoteCount = 0;
        uint256 winningCandidateIndex = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }
        return candidates[winningCandidateIndex].name;
    }
}
