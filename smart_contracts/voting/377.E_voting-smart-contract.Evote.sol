pragma solidity ^0.4.4;

contract Vote
{

    address electionAuthority;
    uint electionEndTime; 
    mapping (string => bool) candidates; // Registered candidates
    mapping (string => uint) votes; // Candidate ID to number of votes
    mapping (string => bool) voters; // Registered voters
    mapping (string => bool) hasVoted; // If a registered voter has voted or not
    mapping (string => string) lastVote; //last vote of each voter
    uint voters_number;
    uint candidates_number;

    function Vote(){
        electionAuthority = msg.sender;
        candidates_number = 0;
        voters_number = 0;
    }

    modifier only_new_voter_address(string addr) {
        if (voters[addr]) throw;
        _;
    }

    modifier only_new_candidate_address(string addr) {
        if (candidates[addr]) throw;
        _;
    }
    
    modifier only_election_authority() {
        if (msg.sender != electionAuthority) throw;
        _;
    }
    
    modifier only_registered_voters(string addr) {
        if (!voters[addr]) throw;
        _;
    }
    
    modifier vote_only_once(string addr) {
        if (hasVoted[addr])
        {
            votes[lastVote[addr]] -= 1;
        }
        _;
    }
    
    modifier only_during_election_time() {
        if (electionEndTime == 0 || electionEndTime > block.timestamp) throw;
        _;
    }
    
    function start_election(uint duration)
        only_election_authority
    {
        electionEndTime = block.timestamp + duration;
    }
  
    function register_candidate(string id)
        only_election_authority
        only_new_candidate_address(id)
    {
        candidates[id]=true;
        candidates_number ++;
    }
    
    function register_voter(string addr)
        only_election_authority
        only_new_voter_address(addr)
    {
        voters[addr] = true;
        voters_number++;
    }
    
    function vote(string addr,string id)
        only_registered_voters(addr)
        vote_only_once(addr)
        //only_during_election_time
    {
        votes[id] += 1;
        lastVote[addr] = id;
        hasVoted[addr] = true;
    }
    
   
    
    function get_candidate(string i)
        constant returns(uint _votes)
    {
        _votes = votes[i];
    }

    function get_num_candidates()
    constant returns(uint num)
    {
        num = candidates_number;
    }


    function get_num_voters()
    constant returns(uint)
    {
        return voters_number;
    }


    function get_votes(string i)
        constant returns(uint)
    {
        return votes[i];
    }

    function get_authority()
    constant returns(address)
    {
    return electionAuthority;
    }


    function set_authority(address adr)
    only_election_authority
    {
        electionAuthority = adr;
    }

}