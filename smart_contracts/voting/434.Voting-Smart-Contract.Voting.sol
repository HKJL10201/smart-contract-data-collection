// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
  

contract Voting is Ownable {
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
    
    WorkflowStatus public statut;

    uint private sumVotes;
    uint private winningProposalId;
    uint private equal;

    address[] private whiteListedVoters;
    mapping(address => Voter) private addressToVoter;

    Proposal[] private proposals;


    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    ///To check if a voter is registred  
    modifier checkRegisteredVoter() {
        require(addressToVoter[msg.sender].isRegistered == true, "Voter not registered");
        _;
    }

    ///To check if a potential voter voted 
    modifier checkVoterVoted() {
        require(addressToVoter[msg.sender].hasVoted == true, "Voter without vote");
        _;
    }

    ///To check if you have the right status what you want to do 
    modifier checkStatut(WorkflowStatus requiredStatus) {
        require(statut == requiredStatus, "It's not the time for doing that");
        _;
    }

    ///Add voters
    function addVoter(address _address) public onlyOwner checkStatut(WorkflowStatus.RegisteringVoters) {
        require(_address != address(0), "You must add a valid address");
        require(addressToVoter[_address].isRegistered == false, "Voter already added");

        whiteListedVoters.push(_address);
        addressToVoter[_address].isRegistered = true;

        emit VoterRegistered(_address);
    }

    ///Add proposals 
    function addProposal(string memory _description) public checkRegisteredVoter checkStatut(WorkflowStatus.ProposalsRegistrationStarted) {
        string memory empty = "";
        require(keccak256(bytes(_description)) != keccak256(bytes(empty)),"Proposal can't be empty.");

        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    ///Function to vote for 1 proposal/voter
    function voteProposal(uint _proposalId) public checkRegisteredVoter checkStatut(WorkflowStatus.VotingSessionStarted) {
        require(proposals.length > _proposalId, "This ProposalID is not correct");
        require(addressToVoter[msg.sender].hasVoted == false, "Already voted");

        addressToVoter[msg.sender] = Voter(true ,true, _proposalId);
        proposals[_proposalId].voteCount++;

        sumVotes++;

        emit Voted(msg.sender, _proposalId);
    }

    ///Start of the voting session
    ///It's mandatory to have more than 1 voter
    function startProposalSession() public onlyOwner checkStatut(WorkflowStatus.RegisteringVoters) {
        require(whiteListedVoters.length > 1, "Voting system need more than 1 voter !");
        WorkflowStatus oldStatus = statut;
        statut = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(oldStatus, statut);
    }

    ///End of the voting session
    function endProposalSession() public onlyOwner checkStatut(WorkflowStatus.ProposalsRegistrationStarted) {
        WorkflowStatus oldStatus = statut;
        statut = WorkflowStatus.ProposalsRegistrationEnded;

        emit WorkflowStatusChange(oldStatus, statut);
    }    

    ///Start of the voting session
    ///It's mandatory to have more than 1 proposal
    function startVotingSession() public onlyOwner checkStatut(WorkflowStatus.ProposalsRegistrationEnded) {
        require(proposals.length > 1, "Voting system need more than 1 proposal !");
        WorkflowStatus oldStatus = statut;
        statut = WorkflowStatus.VotingSessionStarted;

        emit WorkflowStatusChange(oldStatus, statut);
    }

    ///End of the voting session
    ///It's mandatory to have more than 1 vote
    function endVotingSession() public onlyOwner checkStatut(WorkflowStatus.VotingSessionStarted) {
        require(sumVotes >=1, "You have to vote before");
        
        WorkflowStatus oldStatus = statut;
        statut = WorkflowStatus.VotingSessionEnded;

        emit WorkflowStatusChange(oldStatus, statut);
    }

    ///Calculate the winner and change the statut 
    function tallyingVotes() public onlyOwner checkStatut(WorkflowStatus.VotingSessionEnded) {
        uint max = 0;
        equal = 0;
        for(uint i = 0; i < proposals.length; i++) {
            if(proposals[i].voteCount == max) {
                equal = 1;
            }

            if(proposals[i].voteCount > max) {
                equal = 0;
                winningProposalId = i;
                max = proposals[i].voteCount;
            }
        }

        WorkflowStatus oldStatus = statut;
        statut = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(oldStatus, statut);
    }

    ///Return the list of proposals
    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

     ///Return proposal details
    function getOneProposal(uint256 _proposalId) public view returns (Proposal memory) {
        require(proposals.length > _proposalId, "This ProposalID is not correct");
        return proposals[_proposalId];
    }

    ///Return vote of one voter
    function getVote(address _address) public view checkRegisteredVoter checkVoterVoted returns(uint) {
        return addressToVoter[_address].votedProposalId;
    }

    ///Return the list of voters
    function getWhitelistedVoters() public view returns (address[] memory) {
        return whiteListedVoters;
    }

    ///Return the winner (if there is no equality)
    function getWinner() public view checkStatut(WorkflowStatus.VotesTallied) returns(Proposal memory) {
        require(equal==0, "There is no winner, you can revote");
        return proposals[winningProposalId];
    }

}



