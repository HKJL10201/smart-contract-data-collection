// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

contract Election {
 

    struct Candidate {
        uint id;
        string name;
        string proposal;
        uint voteCount;
    }
    struct Voter {
        string name;
        bool voted;
        uint Vote;
        bool delegated;
        address delegate;
    }

    mapping(uint => Candidate) candidates;
    mapping(address => Candidate) Candidates; 
    mapping(address => bool) voters;    
    mapping (address => Voter) voter;
    mapping(address => address) delegates;
    mapping(address => uint256) votesCount;

    enum State { NOT_STARTED, ONGOING, FINISHED}
    State public checkstate;
     uint candidatesCount;
     uint votersCount;
     address  owner;

    constructor() {
        owner = msg.sender;
        checkstate = State.NOT_STARTED;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this operation");
        _;
    }

     /** Add a new candidate
    This function helps to add a new candidate to the election, which can be done only by the admin before the election starts. This function takes the following parameters:       ●	string memory _name 🡪 Name of the candidate
       ●	string memory _proposal 🡪 Election promise of the candidate
       ●	address owner 🡪 Owner of the contract**/

    function addCandidate(string memory _name, string memory _proposal, address _owner) public onlyOwner {
        require(msg.sender == _owner, "Only contract owner can perform this action");
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, _proposal, 0);
    }

     /** Add a new voter
     This function helps to add a voter, which can be done only once by the admin before the election starts. This function takes the given parameters:
        ●	address _voter 🡪 Ethereum address of the voter
        ●	address owner 🡪 Owner of the contract**/

    function addVoter(address _voter, address _owner) public onlyOwner {
        require(!voters[_voter], "This voter already exists");
        require(msg.sender == _owner, "Only contract owner can perform this action");
        voters[_voter] = true;
        votersCount++;
    }

     /**	Cast the vote
     This function helps voter to cast their vote. It has the below two input arguments:
         ●	Candidate ID is the candidate who has to be voted
         ●	Voter address**/

    function vote(uint _candidateId, address _voter) public {
        require(checkstate == State.ONGOING, "Election is not ongoing");
        require(voters[_voter], "You are not authorized to vote");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        require(!voter[_voter].voted, "You have already voted");

          voter[_voter].voted = true;
          voter[_voter].Vote = _candidateId;
          candidates[_candidateId].voteCount++;
    }
       
     /**	Display the candidate details
     This function helps to show candidate details. The input to this function is the ID of the candidate, and in the response, it returns the following parameters:
        ●	ID 🡪 ID of the candidate
        ●	Proposal 🡪 Election promise of the candidate
        ●	Name 🡪 Name of the candidate**/

    function displayCandidate(uint _id) public view returns (uint id, string memory name, string memory proposal, uint voteCount) {
        require(_id > 0 && _id <= candidatesCount, "Invalid candidate ID");

        Candidate memory candidate = candidates[_id];

        return (candidate.id, candidate.name, candidate.proposal, candidate.voteCount);
    }

     /** 	Start Election
     This function helps the admin to start the election (setting the Election state to ONGOING). 
     This function takes the address of the contract owner as an input parameter.**/

    function startElection(address _owner) public onlyOwner {
        require(_owner == owner, "You are not authorized to start the election");

        checkstate = State.ONGOING;
    }

     /**	End the election
     This function helps the admin to end the ongoing election. 
     This function can be called only by the admin (contract owner).**/

    function endElection(address _owner) public onlyOwner {
        require(checkstate == State.ONGOING, "Election is not ongoing");
        require(_owner == owner, "You are not authorized to start the election");

        checkstate = State.FINISHED;
    }

     /**	Delegate the voting right
     This function helps to delegate a voter’s voting rights to someone else.  This function can be called only when the election is going on and by a voter who has not yet voted. This function has the following two input parameters:
        ●	Delegate person address
        ●	Voter address**/

    function delegateVote(address delegateAddress, address ownerAddress) public {
         require(ownerAddress == msg.sender, "Only the owner can delegate their vote.");
         require(delegateAddress != address(0), "Invalid delegate address.");      
         require(votesCount[ownerAddress] == 0, "Owner has already voted.");       
    delegates[ownerAddress] = delegateAddress;
    }

     /**	Show the Winner of the election
     This function helps to show the winner of the election. This function has no input arguments, but it returns the following fields:
         ●	Candidate name
         ●	Candidate ID
         ●	Votes secured**/
    
    function showWinner() public view returns (string memory name, uint winningCandidateId, uint voteCount) {
        //  uint winningCandidateId;
        //  uint voteCount;

         for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > voteCount) {
              voteCount = candidates[i].voteCount;
              winningCandidateId = i;
        }
    }

    return (candidates[winningCandidateId].name, winningCandidateId, voteCount);
    }

       /**	Show election results (candidate wise)
       This function helps to show the votes received by any given candidate. 
       This function takes the candidate ID as input and returns the below fields in response.
           ●	Candidate ID
           ●	Candidate name
           ●	Number of votes received**/

    function showResult(uint _candidateId) public view returns (uint id, string memory name, uint voteCount) {
         require(checkstate == State.FINISHED, "Election is not yet completed.");
         require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID.");

    return (_candidateId, candidates[_candidateId].name, candidates[_candidateId].voteCount);
    }
     
      // view candidate count 
    function candidate_Count() public view returns (uint candiateCount) {
    return candidatesCount;
    }

      //view voters count
    function voter_Count() public view returns (uint voterscount) {
    return votersCount;
    }

      /**	View the voter’s profile
      This function helps to view the voter profile. It takes the voter’s address as input and returns the following fields in response:
           ●	Voter’s name
           ●	The candidate who has been voted
           ●	If the vote is delegated or not**/

    function voterProfile(address voterAddress) public view returns (string memory name, uint Vote, bool delegated, address delegate) {
         Candidate memory candidate = Candidates[voterAddress];
         name = candidate.name;
         Voter storage voterss = voter[voterAddress];
         Vote = voterss.Vote;
         delegate = voterss.delegate;
         delegated = voterss.delegate != address(0);
    }

       // This function is used to view voter . it takes delegate address and voters address

    function getVoter() public view returns (address voteraddress, address delegateaddress) {
         address voterAddress = msg.sender;
         address delegateAddress = voter[voterAddress].delegate;
    return (voterAddress, delegateAddress);
    }

}
