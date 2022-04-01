
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;
import "hardhat/console.sol";

/// @author @courchrishi
/// @title Voting with Delegation

contract Ballot {
    // Declares a complex type (Struct) for representing a single voter



    struct Voter {
        bool voted;     // if true, the person has already voted
        uint vote;      // index of the voted proposal
        uint weight;    // weight will be 1 since this is a non-delegated scenario
    }


    // Declares a complex type (Struct) for a single proposal

    struct Proposal {
        string name;      // short name (up to 32 bytes)
        uint voteCount;         // number of accummulated votes
    }


    // Declares a state variable (or) mapping that stores a 'Voter' struct for each address
    mapping(address => Voter) public voters;
    mapping(uint => bool) public winners;
    

    // A dynamically-sized array of 'Proposal' structs
    Proposal[] public proposals;

    
    /* Declaring an event for capturing every time when someone leads */
    event liveResults(uint256 proposal, uint votes);

    // A function to register the vote

    function vote(uint proposal) external {
       /// Initial checks for the sender before getting qualified as a voter
        Voter storage sender = voters[msg.sender]; // 1. Creating a Voter Struct and mapping to the sender's address

        require(!sender.voted, "Already voted");  // 2. Should not have already voted

        sender.voted = true; // Setting the voted flag to true
        sender.vote = proposal; // Setting the proposed vote to the vote property
        proposals[proposal].voteCount += 1;  // Updating the canditate's votecount
                
    }


    // /// Creates a new ballot to choose one of 'proposalNames'. Initiated at the time of contract deployment
    constructor(string[] memory proposalCandidates) {
        // 'Proposal({...}) creates a temporary proposal object 
        // proposals.push(...) appends it to the end of the proposals array

        for (uint i = 0; i < proposalCandidates.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({ name: proposalCandidates[i], voteCount:0}));
        }
        
    }

    function winningProposal() public view returns (uint winningProposal_) {

        uint winningCount = 0; 

        for(uint i=0; i < proposals.length; i++) {
            if(proposals[i].voteCount > winningCount) {
                winningCount = proposals[i].voteCount;
                winningProposal_ = i;
                }
         }
    }

    function getElectionResult() external view returns(string memory winnerName_){
        winnerName_ = proposals[winningProposal()].name;

    }

}