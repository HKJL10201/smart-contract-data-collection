// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    // structure of a voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    //structure of a proposal
    struct Proposal {
        string description;
        uint voteCount;
    }

    // workflow status for the vote session
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    // Initialize the status to Registering Voters
    WorkflowStatus public voteStatus = WorkflowStatus.RegisteringVoters;

    // Mapping to list all user and toggle the whilisted variable (isRegistered). All voters can see these informations
    mapping(address => Voter) public whitelist;

    // Array to register all user's proposals
    Proposal[] public proposals;

    // Public variable that will contain winner id. Initialy it's 9999 because 0 can be an ID of the winner
    uint public winningProposalId = 9999;

    // Events to track status or user's activity during vote session
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    // Modifier to make functions usable only by whitelisted user
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender].isRegistered == true, "You shoud be registered in the whitelist.");
        _;
    }

    // Private function to toggle status enum change
    function nextStepVoteWorkflow() private onlyOwner {
        require(uint(voteStatus) < 5, "Workflow completed, you can start a new vote using the appropriate function.");
        voteStatus = WorkflowStatus(uint(voteStatus) + 1);
        emit WorkflowStatusChange(WorkflowStatus(uint(voteStatus) - 1), voteStatus);
    }

    // function to start proposal registration
    function startProposalsRegistration() public onlyOwner {
        require(voteStatus == WorkflowStatus.RegisteringVoters, "Registration of voter didn't happend");
        nextStepVoteWorkflow();
    }

    // function to stop proposal registration
    function stopProposalsRegistration() public onlyOwner {
        require(voteStatus == WorkflowStatus.ProposalsRegistrationStarted, "Registration of proposals didn't start");
        nextStepVoteWorkflow();
    }

    // function to start the vote session
    function startVotingSession() public onlyOwner {
        require(voteStatus == WorkflowStatus.ProposalsRegistrationEnded, "Registration of proposals didn't ended");
        nextStepVoteWorkflow();
    }

    // function to stop vote session
    function stopVotingSession() public onlyOwner {
        require(voteStatus == WorkflowStatus.VotingSessionStarted, "Voting session didn't start");
        nextStepVoteWorkflow();
    }

    // function to register user into the whitelist
    function whitelistUser(address _addr) public onlyOwner {
        require(voteStatus == WorkflowStatus.RegisteringVoters, "Current voting status should be 'RegisteringVoters'");
        whitelist[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // function to register proposal into proposals array. If the porposal already exist, the function will return immediately
    function registerProposal(string calldata _description) public onlyWhitelisted {
        require(voteStatus == WorkflowStatus.ProposalsRegistrationStarted, "Current voting status should be 'ProposalsRegistrationStarted'");
        for (uint i=0; i < proposals.length; i++) {
            if (keccak256(abi.encodePacked(proposals[i].description)) == keccak256(abi.encodePacked(_description))) {
                return;
            }
        }
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length -1);
    }

    // function to vote for a proposal increment the vote count
    function voteForProposal(uint _id) public onlyWhitelisted {
        require(voteStatus == WorkflowStatus.VotingSessionStarted, "Current voting status should be 'Voting Session Started'");
        require(_id < proposals.length, "ID missing in proposals");
        proposals[_id].voteCount++;
        emit Voted(msg.sender, _id);
    }

    // function to return the winner
    function choiceWinner() public onlyOwner {
        require(voteStatus == WorkflowStatus.VotingSessionEnded, "Vote session hasn't finish");
        uint biggest;
        for (uint i=0; i < proposals.length; i++) {
            if (proposals[i].voteCount > biggest) {
                biggest = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        nextStepVoteWorkflow();
    }
}