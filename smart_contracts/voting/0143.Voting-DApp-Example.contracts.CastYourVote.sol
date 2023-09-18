pragma solidity ^0.4.18;

contract CastYourVote
{
    
    string[] candidateList;
    mapping(string=>uint8) VotesReceived; // 'A' => 3 Votes, 'B' =>5 votes VotesReceived[A] = 3, VotesReceived[B]=5
    
    event log(string comment, string variable);
    function CastYourVote(string candidateName) public
    {
        
        candidateList.push(candidateName);
        log('candidate List ', candidateList[0]);
        
        
    }
    
    function addCandidates(string candidateName) public
    {
        candidateList.push(candidateName);
    }
    
    function VoteFor(string candidateName) public
    {
		require(isCandidateExist(candidateName));
        VotesReceived[candidateName] = VotesReceived[candidateName]+1;
 
        /*for(uint8 i=0; i<candidateList.length;i++)
        {
            if(keccak256(candidateName)==keccak256(candidateList[i]))
            {
                VotesReceived[candidateList[i]] = VotesReceived[candidateList[i]]+1;
            }
        } */
    } 
    
    function totalVotesReceived(string candidateName) public view returns (uint8 votes)
    {
		require(isCandidateExist(candidateName));
        return VotesReceived[candidateName];
    /*  for(uint8 i=0; i<candidateList.length;i++)
        {
            if(keccak256(candidateName)==keccak256(candidateList[i]))
            {
                return VotesReceived[candidateList[i]];
            }
        }  */ 
    }
	
	
	
	function resetVotes() public {
	
	for(uint8 i=0; i<candidateList.length;i++)
        {
	    VotesReceived[candidateList[i]] = 0;
	}
	
	
	}
	
	
    function isCandidateExist(string candidateName) public view returns (bool isexist)
    {
         for(uint8 i=0; i<candidateList.length;i++)
        {
            if(keccak256(candidateName)==keccak256(candidateList[i]))
            {
                return true;
            }
        }
        return false;
    }
    
    
}