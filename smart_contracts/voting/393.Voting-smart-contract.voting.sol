// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

/*
* @author Olivier David
* @notice smart contract to manage a unique voting session
* @dev many improvments possible
* @custom experimental, don't use this at home!
*/
contract Voting is Ownable { 

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    mapping(address => Voter) private voters;

    struct Proposal {
        string description;
        uint voteCount;
    }
    Proposal[] private proposals;
    uint private winningProposalId;

    bool oneVoterAtLeast;

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    WorkflowStatus public status; // default value first of the list

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    /*
    * @notice the contract owner is registered as a voter
    */
    constructor() {
        registerVoter(msg.sender);
    }

    /*
    * @notice limit access to registered voter
    */
    modifier onlyVoter () {
        require(
            voters[msg.sender].isRegistered == true,
            "You should be a registered voter"
        );
        _;
    }

    /*
    * @notice register a new voter
    * @custom only for contract owner
    */
    function registerVoter(address _address) public onlyOwner {
        require(
            status == WorkflowStatus.RegisteringVoters,
            "Can't register a voter at this step"
        );
        voters[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    /*
    * @notice go to the next step of the voting process
    * @dev
    *   - no proposal and no vote block the process,
    *   - launch the calculation of the result when vote session end
    * @custom only for contract owner
    */
    function nextWorkflowStep() public onlyOwner {
        uint current = uint(status);
        require (
            current < uint(type(WorkflowStatus).max),
            "Last step of the workflow reached"
        );

        // no proposal registered
        if (status == WorkflowStatus.ProposalsRegistrationStarted) {
            require (
                proposals.length > 0,
                "No proposals registered, you can't close this session"
            );
        }

        // no vote registered
        if (status == WorkflowStatus.VotingSessionStarted) {
            require (
                oneVoterAtLeast,
                "No votes registered, you can't close this session"
            );
        }

        status = WorkflowStatus(current + 1);
        emit WorkflowStatusChange(WorkflowStatus(current), status);

        // process result after vote session end
        if (status == WorkflowStatus.VotingSessionEnded) {
            calculateResult();
        }
    }

    /*
    * @notice register a voting proposal
    * @dev several proposals possible for a single voter
    * @custom only for registered voter
    */
    function registerProposal(string memory _description) public onlyVoter {
        require(
            status == WorkflowStatus.ProposalsRegistrationStarted,
            "Propoposal registration session not started"
        );
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposals.length - 1);
    }

    /*
    * @notice get a voting proposal description
    * @dev avoid the full proposal and the number of votes to be public
    * @custom only for registered voter
    */
    function getProposalDescription(uint _proposalId) public view onlyVoter returns (string memory) {
        require(
            status >= WorkflowStatus.ProposalsRegistrationStarted,
            "Propoposal registration session is not ongoing"
        );
        require(
            _proposalId < proposals.length,
            "Unknown proposal"
        );
        return proposals[_proposalId].description;
    }

    /*
    * @notice register a vote
    * @dev one vote by voter
    * @custom only for registered voter
    */
    function vote(uint _proposalId) public onlyVoter {
        require(
            status == WorkflowStatus.VotingSessionStarted,
            "Vote session is not ongoing"
        );
        require(
            voters[msg.sender].hasVoted == false,
            "Only one vote is allowed"
        );
        require(
            _proposalId < proposals.length,
            "Unknown proposal"
        );
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount += 1;
        if (oneVoterAtLeast == false) {
            oneVoterAtLeast = true;
        }
        emit Voted (msg.sender, _proposalId);
    }

    /*
    * @notice check the vote of an address 
    * @dev available after the vote ended
    * @custom only for registered voter
    */
    function getVote(address _address) public view onlyVoter returns (uint) {
        require(
            status >= WorkflowStatus.VotingSessionEnded,
            "The vote session should be ended"
        );
        require(
            voters[_address].hasVoted == true,
            "Voter has not voted"
        );
        return voters[_address].votedProposalId;
    }

    /*
    * @notice get the first proposal of the list with the highest number of votes
    * @dev launched by the nextWorkflowStep function
    * @custom 
    *   - only for registered voter
    *   - improvment possible equality management
    */
    function calculateResult() private {
        uint maxVotes;
        for (uint i;i<proposals.length;i++) {
            if(proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        // change status to votes tallied
        nextWorkflowStep();
    }

    /*
    * @notice return the winner proposalId 
    * @dev available after the votes are tallied
    * @custom only for registered voter
    */
    function getWinner() public view onlyVoter returns (uint) {
        require(
            status == WorkflowStatus.VotesTallied,
            "The votes should be tallied"
        );
        return winningProposalId;
    }

    /*
    * @notice return the winner proposal details
    * @dev "Everyone could verify the details of the winning proposal"
    *      available after the votes are tallied
    * @custom no role access restriction
    */
    function getWinningProposalDetails() public view returns (Proposal memory) {
        require(
            status == WorkflowStatus.VotesTallied,
            "The votes should be tallied"
        );
        return proposals[winningProposalId];
    }
}
