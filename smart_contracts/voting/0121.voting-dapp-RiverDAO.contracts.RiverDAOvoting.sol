// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Voting{
//FOR A SIMPLE USE WITH ERC20 TOKEN

    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 private vToken;

//declaring proposals, voters and status.
    struct Proposal {
        string description;
        uint voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint voteProposalId;
    }

    enum Status {
        RegisteringVoters, /** Status 0 */
        ProposalRegistrationsStart, /** Status 1 */
        ProposalRegistrationsEnd, /** Status 2 */
        VotingSessionStarted, /** Status 3 */
        VotingSessionEnded, /** Status 4 */
        AfterVoting /** Status 5 */
    }

// Stating variables.
    address public administrator;
    Status public state;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    uint public winningProposalId;

//Security modifiers
    modifier Admin {
        require(msg.sender == administrator, "Message sender should be Admin."); 
        _;
    }
    modifier RegisteredVoters {
        require(voters[msg.sender].isRegistered, "You are not registered");
        _;
    }
    modifier Status0 { // ALLOW FUNCTION TO WORK WHEN STATE IS AT "RegisteringVoters".
        require(state == Status.RegisteringVoters, "StateError");
        _;
    }
    modifier Status1 { // ALLOW FUNCTION TO WORK WHEN STATE IS AT "ProposalRegistrationsStart".
        require(state == Status.ProposalRegistrationsStart, "StateError");
        _;
    }
    modifier Status2 { // ALLOW FUNCTION TO WORK WHEN STATE IS AT "ProposalRegistrationsEnd".
        require(state == Status.ProposalRegistrationsEnd, "StateError");
        _;
    }
    modifier Status3 { // ALLOW FUNCTION TO WORK WHEN STATE IS AT "VotingSessionStarted".
        require(state == Status.VotingSessionStarted, "StateError");
        _;
    }
    modifier Status4 { // ALLOW FUNCTION TO WORK WHEN STATE IS AT "VotingSessionEnded".
        require(state == Status.VotingSessionEnded, "StateError");
        _;
    }
    modifier Status5 { // ALLOW FUNCTION TO WORK WHEN STATE IS AT "AfterVoting".
        require(state == Status.AfterVoting, "StateError");
        _;
    }
    

// Status Events
    event VoterRegistered (address voterAddress);
    event ProposalRegStart();
    event ProposalRegEnd();
    event ProposalRegistering(uint proposalId);
    event VotingSessionStarted();
    event AfterVoting();
    event Voted(address voter, uint proposalId);
    event VotesTallied();

    event StatusChange(
        Status previousStatus,
        Status newStatus
    );
    
// CONSTRUCTOR HERE! 

    constructor(address _vToken) {
        vToken = IERC20(_vToken);

        administrator = msg.sender;
        state = Status.RegisteringVoters;
    }


/*
(FOR STATUS MODIFIER EXPLAINATION CHECK MODIFIERS LIST AND ENUM "Status")

Only voters that have equal or more than 1000 VTk will be able
to register to vote and then propose and vote in this smart contract.

The idea is to have an ICO and then people will be able to buy the token
at a DEX if they missed the ICO. In this case we are just going to use token directly
minted from their contract
*/

    function registerVoters() public Status0 {
        require(!voters[msg.sender].isRegistered, "Already registered to vote");
        require(vToken.balanceOf(msg.sender) >= 1000000000000000000000, "Not enough token to register");

        voters[msg.sender].isRegistered = true;
        voters[msg.sender].hasVoted = false;
        voters[msg.sender].voteProposalId = 0;

        emit VoterRegistered(msg.sender);
    }

/*
START OF PROPOSAL FUNCTIONS. 

When 'startProposalReg' function is called no one else
will be able to register to vote and the period for proposals registration will
start. Time available depends on ADMIN. Also, public function for registered voters
to register a proposal for voting.
*/


    // (ADMIN) TO START PROPOSAL PERIOD.
    function startProposalReg() public Admin Status0 {
        state = Status.ProposalRegistrationsStart;

        emit ProposalRegStart();
        emit StatusChange(Status.RegisteringVoters, state);   
    }
    
    // (ADMIN) TO END PROPOSAL PERIOD.
    function endProposalReg() public Admin Status1 {
        state = Status.ProposalRegistrationsEnd;

        emit ProposalRegEnd();
        emit StatusChange(Status.ProposalRegistrationsStart, state);
    }

    //REGISTER A PROPOSAL. SHOULD BE A REGISTERED VOTER TO REGISTER A PORPOSAL.
    function registerProposal(string memory proposalDescription) public RegisteredVoters Status1 {
        proposals.push(Proposal({
            description: proposalDescription,
            voteCount: 0
        }));

        emit ProposalRegistering(proposals.length - 1);
    }

    // GET FUNCTION ID AND DESCRIPTION
    function getProposalNumber() public view returns (uint) {
        return proposals.length;
    }
    function getProposalDescription(uint index) public view returns (string memory) {
        return proposals[index].description;
    }


// END OF PROPOSALS FUNCTIONS.


/*
START OF VOTING FUNCTIONS

ADMIN will only be able to start and end voting period. Time depends on ADMIN.
Also, public function to vote is available for registered voters.
*/
    
    //(ADMIN) VOTE PERIOD START
    function startVoting() public Admin Status2 {
        state = Status.VotingSessionStarted;

        emit VotingSessionStarted();
        emit StatusChange(Status.ProposalRegistrationsEnd, state);
    }

    //(ADMIN) VOTE PERIOD END
    function endVoting() public Admin Status3 {
        state = Status.VotingSessionEnded;

        emit VotingSessionStarted();
        emit StatusChange(Status.VotingSessionStarted, state);
    }


    // PUBLIC VOTING FUNCTION. ONLY REGISTERED VOTERS CAN VOTE.
    function vote(uint proposalId) public RegisteredVoters Status3 {
        require(!voters[msg.sender].hasVoted, "You already voted");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].voteProposalId = proposalId;

        proposals[proposalId].voteCount += 1;
        
        emit Voted(msg.sender, proposalId);
    }


// END OF VOTING FUNCTIONS

/*
START OF AFTERVOTING FUNCTIONS.

Most functions are public to check winning proposalid and descriptions.
ADMIN function is tallyVotes to count votes and set the winning proposal.
*/ 

    //(ADMIN) TALLY OF VOTES
    function tallyVotes() public Admin Status4 {
        uint winningVoteCount = 0;
        uint winningProposalIndex = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }
        winningProposalId = winningProposalIndex;
        state = Status.AfterVoting;

        emit VotesTallied();
        emit StatusChange(Status.VotingSessionEnded, state);
    }

    //CHECK WINNING PROPOSAL ID, DESCRIPTION AND VOTE COUNT.
    function winningID() public view Status5 returns(uint) {
        return winningProposalId;
    }
    function winningDesc() public view Status5 returns(string memory) {
        return proposals[winningProposalId].description;
    }
    function winningCount() public view Status5 returns(uint) {
        return proposals[winningProposalId].voteCount;
    }

// END OF AFTERVOTE functions


/*
START OF CEHCK FUNCTIONS.

Simple functions to check admin, if voters are registered and also
the current Status of the voting Dapp.
*/ 
    //CHECK IF YOUR ADDRESS IS ALREADY REGISTERED
    function registered(address voterADDR) public view returns(bool) {
        return voters[voterADDR].isRegistered;
    }

    //CHECK IF ADDRESS IS THE ADMIN
    function admin(address _address) public view returns(bool) {
        return _address == administrator;
    }

    //CHECK CURRENT STATUS OF VOTING DAPP
    function currentStatus() public view returns(Status) {
        return state;
    }

/**                                            END OF RIVER DAO VOTING DAPP. F1022                                                                        */
}