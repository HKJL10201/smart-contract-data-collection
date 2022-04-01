pragma solidity ^0.4.21;
contract Election {  
    address electionAuthority;
    uint electionEndTime; 
    string[] candidates; // Registered candidates
    mapping (string => uint) votes; // Candidate ID to number of votes
    mapping (address => bool) voters; // Registered voters
    mapping (address => bool) hasVoted; // If a registered voter has voted or not
    
    function Election(){
        electionAuthority = msg.sender;
    }
    
    modifier only_election_authority() {
        if (msg.sender != electionAuthority) throw;
        _;
    }
    
    modifier only_registered_voters() {
        if (!voters[msg.sender]) throw;
        _;
    }
    
    modifier vote_only_once() {
        if (hasVoted[msg.sender]) throw;
        _;
    }
    
    modifier only_during_election_time() {
        if (electionEndTime > 0 && electionEndTime < block.timestamp) throw;
        _;
    }
    
    function start_election(uint duration) 
        only_election_authority
    {
       electionEndTime = block.timestamp + duration;
    }
  string id1;
      
        uint i;
        uint j = 5;
    function register_candidate(string id) 
        only_election_authority
       {
   
       if(Valid_candidate(id))
        {candidates.push(id);}
        
        
    }
    // to validate candidate's name repeat name will not allowed that will not stored by default
    function Valid_candidate(string _id) returns (bool)
    {
        
        if(candidates.length != 0)
        {
        
        for(i=0;i<candidates.length; i++)
        {
            
            
        if(check(_id,candidates[i]))
        {
            return false;
            break;
        }
        
        }
        //return false;
        
    }
       return true;
     
    }
    
    // function to compare two strings 
    function check(string a,string b) returns (bool)
    {
        return (keccak256(a) == keccak256(b));
    }
    
    function register_voter(address addr)
        only_election_authority
    {
        voters[addr] = true;
    }
    
    function vote(string id)
        only_registered_voters
        vote_only_once
        only_during_election_time
    {
        votes[id] += 1;
        hasVoted[msg.sender] = true;
    }
    
    function get_num_candidates() constant returns(uint) {
        
        return candidates.length;
    }
    
    function get_candidate(uint i)
        constant returns(string _candidate, uint _votes)
    {
        _candidate = candidates[i];
        _votes = votes[_candidate];
    }
}
