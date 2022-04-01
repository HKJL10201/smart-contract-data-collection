// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @title Voting
 * @dev Implements voting process along with vote delegation
 */

contract Voting is Ownable {


    WorkflowStatus public _wfs ;

    Proposal public _winningProposal;

    mapping(address => Voter) public voters;
    address[] public adresses;

  
    Proposal[] public proposals;

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
    event ProposalRegistered(Proposal propal);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    function changeStatus(WorkflowStatus _toThisWorkflow) internal {
        emit WorkflowStatusChange(_wfs, _wfs=_toThisWorkflow);
    }
   function startRegisteringVoters() public onlyOwner {
        changeStatus(WorkflowStatus.RegisteringVoters);
   }
   function startProposalRegistration() public onlyOwner {
        changeStatus(WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
   }
   function stopProposalRegistration() public onlyOwner {
        changeStatus(WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
   }
   function startVotingSession() public onlyOwner {
        changeStatus(WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
   }
   function stopVotingSession() public onlyOwner {
        changeStatus(WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
   }

   function votesTallied() public onlyOwner {
        changeStatus(WorkflowStatus.VotesTallied);
        emit VotesTallied();
   }

   function registerVoter( address _voter) public onlyOwner {

       require(_wfs==WorkflowStatus.RegisteringVoters, "Voting must be in Registering status");
       require(!voters[_voter].isRegistered, "voter Already registered");


       voters[_voter] = Voter({isRegistered: true, hasVoted:false, votedProposalId:0});
       adresses.push(_voter);
       

       emit VoterRegistered(_voter);
   }

    /**
     * @dev Give your vote 
     * @param _proposalId index of proposal in the proposals array
     */
    function vote(uint _proposalId) public {

     require(_wfs==WorkflowStatus.VotingSessionStarted, "Voting must be Opened");


        Voter storage sender = voters[msg.sender];
        require(sender.isRegistered, "voter has to be registered before voting");
        require(!sender.hasVoted, "Already voted.");

        sender.hasVoted = true;

        // If '_proposalId' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.

        proposals[_proposalId].voteCount++;
        emit Voted (msg.sender, _proposalId);

    }

    /**
     * @dev Give your proposal 
     * @param _description of proposal to add in the proposals array
     */
    function giveProposal(string memory _description) public {

        require(_wfs==WorkflowStatus.ProposalsRegistrationStarted, "Voting must be in Registration of Proposals mode");

        Proposal memory propal = Proposal({description : _description, voteCount: 0});

        proposals.push(propal);

        emit ProposalRegistered(propal);

    }

   function getProposals() public view returns(Proposal[] memory){
       return proposals;
   }


   function getAdresses() public view returns(address[] memory){
       return adresses;
   }

   function getWorkFlowStatus() public view returns (string memory) {


        if ( _wfs == WorkflowStatus.RegisteringVoters ) return 'RegisteringVoters';
        if ( _wfs == WorkflowStatus.ProposalsRegistrationStarted ) return 'ProposalsRegistrationStarted';
        if ( _wfs == WorkflowStatus.ProposalsRegistrationEnded ) return 'ProposalsRegistrationEnded';
        if ( _wfs == WorkflowStatus.VotingSessionStarted ) return 'VotingSessionStarted'; 
        if ( _wfs == WorkflowStatus.VotingSessionEnded ) return 'VotingSessionEnded'; 
        if ( _wfs == WorkflowStatus.VotesTallied ) return 'VotesTallied'; 
 
        // Default

        return 'RegisteringVoters';
 
   }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function winningProposal() internal view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }

        return winningProposal_;
    }
    /** 
     * @dev Calls winningProposal() function to get the index of the winner contained in the proposals array and then
     * @return winnerName_ the name of the winner
     */
    function winnerName() public view
            returns (string memory)
    {

        return proposals[winningProposal()].description;

    }

}