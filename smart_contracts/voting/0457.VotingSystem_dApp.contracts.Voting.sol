// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./Ownable.sol";

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
    event Voted(address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    uint private winningProposalId;
    uint numberProposals;
    address[] public listAddress;
    mapping(address => Voter) voters;
    string[] proposalsIndex;
    mapping(string => Proposal) public proposals;
    WorkflowStatus private status;
    
    modifier checkStatus(WorkflowStatus _status) {
        require(status == _status, "Invalid Step");
        _;
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function getStatus() public view returns(WorkflowStatus) {
        return status;
    }

    function getAddresses() public view returns(address[] memory) {
        return listAddress;
    }
    
    function changeStatus(WorkflowStatus _status) internal onlyOwner {
        emit WorkflowStatusChange(status, _status);
        status = _status;
    }
    
    function voterRegister(address _voter) public onlyOwner checkStatus(WorkflowStatus.RegisteringVoters) {
        require(voters[_voter].isRegistered == false, "Already Registered");
        voters[_voter].isRegistered = true;
        listAddress.push(_voter);
        emit VoterRegistered(_voter);
    }

    function isRegistered(address _address) public view returns (bool) {
        return voters[_address].isRegistered;
    }
    
    function proposalsRegistrationStart() public onlyOwner checkStatus(WorkflowStatus.RegisteringVoters) {
        changeStatus(WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
    }
    
    function proposalRegister(string memory _description) public checkStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        require(voters[msg.sender].isRegistered == true, "Voter not Registered");
        require(bytes(proposals[_description].description).length == 0, "Proposal Already Registered");
        //proposals.push(Proposal(_description, 0));
        proposalsIndex.push(_description);
        proposals[_description] = Proposal(_description, 0);
        emit ProposalRegistered(numberProposals);
        numberProposals++;
    }
    
    function proposalsRegistrationEnd() public onlyOwner checkStatus(WorkflowStatus.ProposalsRegistrationStarted) {
        require(numberProposals > 1, "We need more proposals");
        changeStatus(WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
    }
    
    function getAllDescription() public view returns(string[] memory) {
        require(status >= WorkflowStatus.ProposalsRegistrationStarted, "Invalid Step");
        return proposalsIndex;
    }
    
    function votingSessionStart() public onlyOwner checkStatus(WorkflowStatus.ProposalsRegistrationEnded) {
        changeStatus(WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }
    
    function vote(uint _proposalId) public checkStatus(WorkflowStatus.VotingSessionStarted) {
        require(voters[msg.sender].isRegistered == true, "Voter not Registered");
        require(voters[msg.sender].hasVoted == false, "Vote already taken");
        require(_proposalId <= numberProposals - 1, "Invalid proposal");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[proposalsIndex[_proposalId]].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }

    function whoDidYouVoteFor(address _address) public view checkStatus(WorkflowStatus.VotingSessionStarted) returns(uint) {
        require(voters[_address].isRegistered == true, "Not Registered");
        require(voters[_address].hasVoted == true, "Did Not Vote");
        return voters[_address].votedProposalId;
    }
    
    function votingSessionEnd() public onlyOwner checkStatus(WorkflowStatus.VotingSessionStarted) {
        changeStatus(WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
    }
    
    /*
    *   @notice: Counts all the votes and defines the winning proposal
    *   @return The winning ID proposal
    */
    function defineWinner() public onlyOwner checkStatus(WorkflowStatus.VotingSessionEnded) returns(uint) {
        for (uint i = 0; i < numberProposals; i++) {
            if ( proposals[proposalsIndex[winningProposalId]].voteCount < proposals[proposalsIndex[i]].voteCount)
                winningProposalId = i;
        }
        changeStatus(WorkflowStatus.VotesTallied);
        emit VotesTallied();
        return winningProposalId;
    }

    function getWinner() public view checkStatus(WorkflowStatus.VotesTallied) returns(string memory) {
        return string(proposals[proposalsIndex[winningProposalId]].description);
    }
}