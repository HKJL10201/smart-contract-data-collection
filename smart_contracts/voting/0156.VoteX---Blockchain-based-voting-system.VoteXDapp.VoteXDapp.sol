pragma solidity ^0.4.18;
contract Voting{

	mapping(bytes32=>uint8) public votesRecieved;
	mapping(bytes32=>bool) public voted; //true if already voted and false if not voted
    address owner;
	bytes32[] public candidateList;

	constructor() public{
		owner=msg.sender;
	    
	} 
	modifier onlyOwner{
	    require(msg.sender==owner);
	    _;
	}

    function setCandidateName(bytes32 candidateNames) onlyOwner public
    {
         candidateList.push(candidateNames);
    }
    
	function totalVotesFor(bytes32 candidate) public view returns(uint8)
	{
		require(validCandidate(candidate));
		return(votesRecieved[candidate]);
	}

	function voteForCandidate(bytes32 candidate) public{
		require(validCandidate(candidate));
		require(voted[candidate]==false);
		votesRecieved[candidate]+=1;
		voted[candidate]=true;
	} 

	function validCandidate(bytes32 candidate) view public returns(bool)
	{
		for(uint i=0;i<candidateList.length;i++)
		{
			if(candidateList[i]==candidate){
				return true;
			}
		}
		return false;
	}

	



}
