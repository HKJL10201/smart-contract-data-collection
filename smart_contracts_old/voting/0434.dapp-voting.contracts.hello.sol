// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0 ;

contract Voting {
    
    address public admin ;
    
    bool voting_started ;
    
    uint[] ids_of_candidates ;
    
    struct Voter {
        bool allowed ; // is he allowed to vote
        uint8 weight ;
        uint  voteTo ;
    }
    
    struct Candidate {
        uint candidate_id ;
        uint no_of_votes ;
    }
    
    modifier adminonly {
      require(msg.sender == admin , "Admins Only");
      _;
   }
    
    modifier has_started {
        require(voting_started == true , "Voting yet to begin") ;
        _;
    }
    
    mapping(address => Voter) public voters ;
    
    mapping(uint => Candidate) public candidates ;
    
    
    
    constructor(uint[] memory _ids_of_candidates)  {
        admin = msg.sender ;  // setting the admin 
        
        for(uint i =0 ; i<_ids_of_candidates.length ; i++)
        {
            candidates[_ids_of_candidates[i]] = 
                Candidate({
                    candidate_id : _ids_of_candidates[i] ,
                    no_of_votes : 0 
                    }) ;
                
        }
        
        voting_started = false  ;
        ids_of_candidates = _ids_of_candidates ;
    }
    
    
    function start_voting() public adminonly {
        require(voting_started == false , "Voting already started") ;
        voting_started = true ;
    }
    
    function end_voting() public adminonly {
        require(voting_started == true , "Voting already ended") ;
        voting_started = false ;
    }
    
    function givevoteright(address voter) public adminonly {
        require(voters[voter].allowed == false, "Already has rights to vote") ;
        require(voters[voter].weight ==0 , "Already Voted" ) ;
        
        voters[voter].allowed = true ;
        voters[voter].weight = 1 ;
    }
    
    function givevoteTo(uint  _id) public has_started {
        require(voters[msg.sender].allowed , "Voter Not allowed to vote");
        require(voters[msg.sender].weight == 1 , "Already voted") ;
        require(candidates[_id].candidate_id == _id , "No such Candidate") ;
        candidates[_id].no_of_votes += voters[msg.sender].weight ;
        voters[msg.sender].weight = 0 ;
        
        // candidates[_id].no_of_votes ++ ;

    }
  
    function declareResults() public view returns (uint[] memory , uint[] memory) {
        require(voting_started == false , "Voting has not ended") ;
        uint[]    memory _ids = new uint[](ids_of_candidates.length);
        uint[]    memory _candidate_votes = new uint[](ids_of_candidates.length);
        for(uint i=0 ; i < ids_of_candidates.length ;i++ )
        {
                _ids[i] =  candidates[ids_of_candidates[i]].candidate_id  ;
                _candidate_votes[i] = candidates[ids_of_candidates[i]].no_of_votes  ;
        }
        
        return(_ids , _candidate_votes) ;
    }
    
    
}

