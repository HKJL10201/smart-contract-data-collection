// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2; // This will generate a cautionary warning.

//import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.4.0/contracts/access/Ownable.sol";

/**
 * @title voteContract
 * @dev Store & retrieve value in a variable
 */

contract VoteApp  {
    address payable public owner; // owner of the contract
    address payable public winner; // winner
    address payable public contractAddress; //address to collect funds
    uint256 public contributionAmount; // contribution required to vote
    uint256 public numberOfDays = 3; // duration of the voting
    uint256 public raisedAmount; // the sum of all contributions
    uint256 public deadline; //the end of the voting

    // Contributors and Candidates
    struct Contributor {
        uint256 hasVoted; // one user can vote only once, true=1, false=0
    }

    struct Candidate {
        address payable candidate; // candidate
        // uint256 isRegistered; // candidate is registered true=1, false=0
        uint256 numberOfVotes; // the number of votes collected
    }

    mapping(address => Contributor) public contributors;
    mapping(address => Candidate) public candidates;

    constructor() {
        owner = msg.sender;
        deadline = block.timestamp + numberOfDays * 1 days;
        contributionAmount = 10000000000000000 wei;
        contractAddress = payable(address(this));
    }

    // Array with candidates
    Candidate[] public allCandidates;

    // Workflow
    enum WorkflowStatus {
        CandidateRegistration,
        VotingSessionStarted,
        VotingSessionEnded
    }

    // Events
    WorkflowStatus currentStatus = WorkflowStatus.CandidateRegistration;

    event VotingSessionStarted();
    //event Contributed (address contibutor, address candidate);
    //event FundsWired(address winner, address owner);
    event VotingSessionEnded();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);


    // Modifiers
    modifier onlyOwner() {
        require(
            msg.sender == owner, "Only owner can use this function"
        );
        _;
    }

    modifier notVoted(address _address) {
        require(contributors[_address].hasVoted == 0,
            "One user can only vote once!"
        );
        _;
    }

    modifier isNotExpired() {
        require(
            block.timestamp < deadline,
            "Voting has ended."
        );
        _;
    }

    modifier isExpired() {
        require(
            block.timestamp >= deadline,
            "Voting is still online"
        );
        _;
    }

    modifier hasStatus(WorkflowStatus status) {
        require(keccak256(abi.encodePacked(currentStatus)) == keccak256(abi.encodePacked(status)), "You cannot do this, invalid workflow status");
        _;
    }

    modifier hasEnoughFunds(address _adress) {
        require(msg.sender.balance >= contributionAmount,
            "0.01 eth is required to contribute."
        );
        _;
    }


    // create vote
    function createVoting(address[] memory _candidates) public onlyOwner hasStatus(WorkflowStatus.CandidateRegistration) {
        emit VotingSessionStarted();
        emit WorkflowStatusChange(WorkflowStatus.CandidateRegistration, WorkflowStatus.VotingSessionStarted);
        currentStatus = WorkflowStatus.VotingSessionStarted;

        for (uint i=0; i < _candidates.length; i++) {
            allCandidates.push(Candidate(payable(_candidates[i]), 0));
        }
    }

    //Contibute
    function contribute(address _candidate) public payable isNotExpired notVoted(msg.sender) hasEnoughFunds(msg.sender) hasStatus(WorkflowStatus.VotingSessionStarted) {

        require(
            msg.value == contributionAmount,
            "You can only contribute with 0.01 eth"
        );

        contributors[msg.sender].hasVoted = 1; // voted
        raisedAmount += msg.value; // increase the entire amount raised
        candidates[_candidate].numberOfVotes += 1; //increase the candidate's amount
        contractAddress.transfer(msg.value);
        //emit Contributed(msg.sender, _candidate);
    }


    // stop vote
    function endVoting() public payable isExpired hasStatus(WorkflowStatus.VotingSessionStarted) {
        emit VotingSessionEnded();
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
        currentStatus = WorkflowStatus.VotingSessionEnded;


        //find winner
        uint winningAmount = 0;
        for (uint i = 0; i < allCandidates.length; i++) {
            if (allCandidates[i].numberOfVotes > winningAmount) {
                winningAmount = allCandidates[i].numberOfVotes;
                winner = allCandidates[i].candidate;
            }

            //send 90% of the amount rised to the winner wallet
            uint256 winnerPrize = raisedAmount * 9 / 10 ;
            winner.transfer(winnerPrize);
        }
    }


    function wireFundsToOwner() public onlyOwner hasStatus(WorkflowStatus.VotingSessionEnded) {

        //send 10% of the amount rised to the admin wallet
        uint256 adminPrize = raisedAmount / 10;
        owner.transfer(adminPrize);

        //emit FundsWired(winner, owner);
        //emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.RewardWiring);
    }

    function getRaisedAmount () public view returns (uint256) {
        uint256 raisedAmount_;
        raisedAmount_ = raisedAmount;
        return raisedAmount_;
    }
}