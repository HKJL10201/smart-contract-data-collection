// SPDX-License-Identifier: MIT

pragma solidity^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

///@title A simple voting smart contract
///@author Kilian Mongey
///@notice This contract was made for training only, no safety check were made

contract Voting is Ownable {
    
    ///@notice laying out our usefull variables
    
    uint startOfProposals;
    uint endofProposals;
    uint startOfVotes;
    uint endOfVotes;
    string public nameOfVote;
    uint public winningProposalId;
    uint votersCount;
    
     ///@notice we will create a mapping for our struct Voter
    ///@ALYRA, I decided to add an extra bool hasProposed to be able to know if user proposed an idea 
    
    struct Voter {
        bool isRegistered;
        bool hasProposed;
        bool hasVoted;
        uint votedProposalId;
        address userid;
    }
    
     ///@notice here the easiest way I found to query informations was through an array, I decided to go with a proposal array
    ///@ALYRA, I decided to add a uint proposalId to keep better track of the particular Id

    struct Proposal {
        string description;
        uint proposalId;
        uint voteCount;
    }
    
    Proposal[] propositions;
    address[] whiteList;
    
    ///@notice we will keep track of our state using these enum
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
      WorkflowStatus state;
    
    ///@notice I decided to go with only 1 mapping here, even though I probably could've 
    /// made one for our proposal array, but I found it easier using an array 
    
    mapping (address => Voter) public voters;

    ///@notice Here is the list of our events
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    ///@notice Only our contract creator will be allowed to add new addresses(users)
    ///@dev We then require that the address isn't already in our list,
    
    function addToWhiteList(address _address) public onlyOwner {
        
        // require(voters[_address].isRegistered == false, "This address is already whiteListed");
        
        voters[_address].isRegistered = true;
        whiteList.push(_address);
        votersCount++;
        emit VoterRegistered(_address);
    }

    function getWhiteList() public view returns(address[] memory) {
        return whiteList;
    }
    
    ///@notice this is our function to start the proposal phase
    /// we want the admin to be in control so he can choose when to start at any point in time
    
    function startProposals() public onlyOwner {
        
        require(state == WorkflowStatus.RegisteringVoters, "The vote must admit voters first");
        
        // nameOfVote = _nameOfVote;
        startOfProposals = block.timestamp;
        state = WorkflowStatus.ProposalsRegistrationStarted;
        
        emit ProposalsRegistrationStarted();
        
    }
    
     ///@notice same here our admin has all the rights, he can choose to end the proposal period whenever he wants
    ///!!ToThinkOf!! maybe implementing a require(at least 1 hour of proposals)
    /// since this contract is for testing better to not lock our timer(more flexibility)
    
    function endProposals(uint _endofProposals) public onlyOwner {
        
        require(state == WorkflowStatus.ProposalsRegistrationStarted);
        // require(_endofProposals > 1 hours, "Admin should at least leave one hour for every one registered to propose");
        
        endofProposals = _endofProposals + startOfProposals;
        state = WorkflowStatus.ProposalsRegistrationEnded;
        
        emit ProposalsRegistrationEnded();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }
    
     ///@notice This is a helper function, first for me , 
    ///then it also helps our user to check the state of the contract/votingProcess
    
    function getState() public view returns(WorkflowStatus) {
      return state; 
    }
            
    ///@notice Before allowing to vote we want to be sure the msg.sender has the right to propose
    /// check that he hasn't proposed yet
    /// check that the state for our contract is set to proposal started
    ///@dev we will push our new propositions with the description, id and voteCount
    ///@dev then we initiate the new state of our msg.sender to hasProposed = true 
    ///!!ToSee!! maybe it would've been a better choice using a mapping here 
    
    function proposals(string memory _description) public {
        
        require(voters[msg.sender].isRegistered == true);
        require(voters[msg.sender].hasVoted == false);
        require(state == WorkflowStatus.ProposalsRegistrationStarted, "The time for proposals has ended");
        
        propositions.push(Proposal(_description, propositions.length, 0));
        voters[msg.sender].hasProposed = true;
        
        emit ProposalRegistered(propositions.length);
        
    }
    
    ///@notice The constructor of the Smart contract will once again have the full control of the voting system
    /// he can initiate it when he pleases
    ///!!improvementPossible!! make the voting period a minimum of xTime
    ///@dev we require that the current state == proposalRegistrationEnded
    /// also we need to make sure that there is at least 2 proposals before starting a vote
    /// We can then initiate the voting session, and change our state
    
    function startVoting() public onlyOwner {
        
        require(state == WorkflowStatus.ProposalsRegistrationEnded, "The propositions period has not ended yet");
        require(propositions.length >= 1, "This is not a dictature, we need more proposals");
        
        startOfVotes = block.timestamp;
        state = WorkflowStatus.VotingSessionStarted;
        
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }
    
    ///@notice The constructor will be able to stop the votingSession at any point in time
    /// We obviously need to make sure that the state == VotingSessionStarted
    ///@dev The owner will be able to program a timer to end the voting session
    /// we then initiate our state to VotingSessionEnded
    
    function stopVotes(uint _timeToStopVotes) public onlyOwner {
        
        require(state == WorkflowStatus.VotingSessionStarted, "The session hasn'e even started so you can't stop it obviously");
        //require(_timeToStopVotes > 1 hours, "The voting period should at leat last one hour");
        
        endOfVotes = _timeToStopVotes + startOfVotes;
        state = WorkflowStatus.VotingSessionEnded;
        
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        
    }
    
    ///@notice The fun part start, we will authorize our isRegistered users to vote for their favorite proposal
    ///@dev We need to make sur of a few things, our state must be == to VotingSessionStarted, the msg.sender == isRegistered
    /// the input from the user must be a valid index number, and finally the msg.sender can only vote once
    ///@dev we will administrate our vote to _proposalNumber that will give it to our votedProposalId
    /// then we incremente voteCount by one, and finally we set hasVoted to true
    
    function votingTimeBaby(uint _proposalNumber) public {
        
        require(state == WorkflowStatus.VotingSessionStarted, "The session for voting hasn't started or has finished, try again next time");
        require(voters[msg.sender].isRegistered == true, "You are not allowed to vote man !");
        require(_proposalNumber >= 0 && _proposalNumber < propositions.length, "The index you gave doesn't exist...");
        require(voters[msg.sender].hasVoted == false, "You think you can vote twice ? little cheater");
        
        voters[msg.sender].votedProposalId = _proposalNumber;
        propositions[_proposalNumber].voteCount++;
        voters[msg.sender].hasVoted = true;
        
        emit Voted(msg.sender, _proposalNumber);
        
    }
    
    ///@notice creating a helper function(for remix) to find our proposals[]
    
     function getProposals() public view returns(Proposal[] memory) {
        return propositions;
    }

    ///@notice Here we will use a for loop to iterate through our voteCount and get the voteCount who has the most votes
    ///@dev Firstly make sure that the voting session has ended.
    ///@dev Seeting a counter to iterate = winningVoteCount
    ///@dev we then make sure to change our state
    
    
   function winningProposal() public onlyOwner {
       
       require(state == WorkflowStatus.VotingSessionEnded, "The voting session has not ended yet");
       
        uint winningVoteCount;
    
            for (uint i = 0; i < propositions.length; i ++) {
        
              if (propositions[i].voteCount > winningVoteCount) {
                winningVoteCount = propositions[i].voteCount;
                winningProposalId = i;
        
               }
      
            }
            
            state = WorkflowStatus.VotesTallied;
            emit VotesTallied();
            
    }
    
     ///@notice We then set our indexWinner to the public var "winningProposalId" so everyOne can see the winner
    
    function showWinner() public view returns(uint) {
        
        require(state == WorkflowStatus.VotesTallied);
        
        return  winningProposalId;
    }

    
}