pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
contract EVoting {
    address public admin; // admin or chairperson decides voting
    uint public start_voting_time;
    uint public end_voting_time;
    mapping(bytes32 => bool) public voter_email_ID_hash; //stores the hashes of the voter emailID
    mapping(bytes32 => bool) public candidate_emailID; //stores the emailID of the candidates 
    mapping(bytes32 => bool) public votedHashes; //stores the hashes of the voters email ID
//--- do we require has of roll no or email id above??
    uint public totalVotes;
    
    // Admin details
    struct VotingCommissionDetails {
        string adminName;             
    }VotingCommissionDetails public votingcommissionDetails;

    constructor(string memory _adminName)  {
        // Initilizing default values
        votingcommissionDetails = VotingCommissionDetails(_adminName );
        admin = msg.sender;
        
    }

    function getAdmin() public view returns (address, string memory) {
    return (admin, votingcommissionDetails.adminName);
    }  
    
    modifier onlyadmin() {
        // Modifier for only admin access
        require(msg.sender == admin);
        _;
    }
   //----------------------------------------------------------------- 
    function addVoter(bytes32 _voterHash) public onlyadmin {
        voter_email_ID_hash[_voterHash] = true;
    }
    
    function addCandidate(bytes32 _candidate_email) public onlyadmin {
        candidate_emailID[_candidate_email] = true;
    }
 //----------------------------------------------------------------------   
    function vote(bytes32 _voterHash, bytes32 _candidate_email) public {
        require(block.timestamp > start_voting_time, "Election has not started yet.");
        require(block.timestamp < end_voting_time, "Election has ended.");
        require(voter_email_ID_hash[_voterHash], "Invalid voter hash.");
        require(candidate_emailID[keccak256(abi.encodePacked(_candidate_email))], "Invalid candidate email ID.");
        require(!votedHashes[keccak256(abi.encodePacked(_voterHash))], "You have already voted.");
                votedHashes[keccak256(abi.encodePacked(_voterHash))] = true;
        totalVotes++;
    }
  //------------------------------------------------------------------------------  
    function setStartVotingTime(uint _start_voting_time) public onlyadmin {
        require(block.timestamp < _start_voting_time, "Set Starting time for voting");
        start_voting_time = _start_voting_time;
    }

    function setEndVotingTime(uint _end_voting_time) public onlyadmin {
        require(block.timestamp < _end_voting_time, "Set Starting time for voting");
        end_voting_time = _end_voting_time;
    }
    function extendVotingTime(uint _extendTime) public onlyadmin {
        end_voting_time = end_voting_time + _extendTime;
    }
    
}
