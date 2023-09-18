// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

contract E_Voting {
   
    address public admin; // admin or chairperson decides voting
    uint256 CandidateCount; // define candidate count
    uint256 VoterCount;     // define no of voters count
    uint public votingStartTime;    // define voting time   
    uint public end_voting;         // define end voting time
//-------------------------------------------------------------------
     struct ElectionDetails {
        string adminName;             
    }
    ElectionDetails public electionDetails;

    constructor(string memory _adminName)  {
        // Initilizing default values
        electionDetails = ElectionDetails(_adminName );
        admin = msg.sender;
        CandidateCount = 0;
        VoterCount = 0;
        votingStartTime = block.timestamp;
        end_voting = block.timestamp + (2 days);
    }

    function getAdmin() public view returns (address, string memory) {
    return (admin, electionDetails.adminName);
    }  
    
    modifier onlyadmin() {
        // Modifier for only admin access
        require(msg.sender == admin);
        _;
    }
 //--- define structure for candidates----------------------------------------
    struct Candidate {
        uint256 candidateId;    // ID can be roll_no
        string name;
        string emailId;
        uint256 voteCount;          // no of votes of the candidate
    }
    mapping(uint256 => Candidate) public candidateDetails;

    // Adding new candidates
    function addCandidate(string memory _name, string memory _emailId) public  onlyadmin {
            CandidateCount++;
            candidateDetails[CandidateCount] = Candidate(CandidateCount, _name, _emailId, 0);
            }
    // Get candidates count
    function getTotalCandidate() public view returns (uint256) {
        // Returns total number of candidates
        return CandidateCount;
    }

//------------------------------------------------------------
    // structure for  a voter
    struct Voter {
        address voterAddress;
        string name;
        string roll_no;
        bool isRegistered;
        bool isVerified;
        bool hasVoted;    
    }
    address[] public voters; // Array of address to store address of voters
    mapping(address => Voter) public voterDetails;

    // Request to be added as voter
    function registerAsVoter(string memory _name, string memory _roll_no) public {
        Voter storage newVoter = voterDetails[msg.sender];
        require(!newVoter.isRegistered, "You are already registered as a voter.");
        newVoter.voterAddress = msg.sender;
        newVoter.name = _name;
        newVoter.roll_no = _roll_no;
        newVoter.hasVoted = false;
        newVoter.isVerified = false;
        newVoter.isRegistered = true;

        voters.push(msg.sender);
        VoterCount++;
        }

         // Get voters count
        function getTotalVoter() public view returns (uint256) {
        // Returns total number of voters
        return VoterCount;
    }

///_____________________________________________________________________
// Verify voter
    function verifyVoter(bool _verifedStatus, address voterAddress) public
        // Only admin can verify
        onlyadmin
    {
        voterDetails[voterAddress].isVerified = _verifedStatus;
    }

//----------------------------------------------------------------------
    modifier onlyDuringVotingPeriod() {
        require(block.timestamp >= votingStartTime && block.timestamp <= end_voting, "Voting period has not started or has ended");
        _;
    }
    function vote(uint256 candidateId) public onlyDuringVotingPeriod {
        require(voterDetails[msg.sender].hasVoted == false, "You have already voted");
        require(voterDetails[msg.sender].isVerified == true, "You need to be verified to vote");
        require(candidateId > 0 && candidateId <= CandidateCount, "Invalid candidate ID");
        require(block.timestamp <= end_voting, "Voting period has ended");
        
        candidateDetails[candidateId].voteCount += 1;
        voterDetails[msg.sender].hasVoted = true;
    }
//-----------------------------------------------------------------------------------------------------
   //Define the function to get the voting results (restricted to the owner)
    function getVotingResults() public view returns (Candidate[] memory, Candidate[] memory) {
        require(block.timestamp > end_voting || msg.sender == admin, "Voting is still in progress.");
        Candidate[] memory results = new Candidate[](CandidateCount);
        uint256 winnerVoteCount = 0;
        uint256 tieCount = 0;
        uint256[] memory tieIndices = new uint256[](CandidateCount);
        for (uint256 i = 0; i < CandidateCount; i++) {
            results[i] = candidateDetails[i];
            if (candidateDetails[i].voteCount > winnerVoteCount) {
                winnerVoteCount = candidateDetails[i].voteCount;
                tieCount = 0;
                tieIndices[tieCount] = i;
            } else if (candidateDetails[i].voteCount == winnerVoteCount) {
                tieCount++;
                tieIndices[tieCount] = i;
            }
        }
        Candidate[] memory winners = new Candidate[](tieCount + 1);
        for (uint256 i = 0; i <= tieCount; i++) {
            winners[i] = candidateDetails[tieIndices[i]];
        }
        return (results, winners);
    }

}




    

