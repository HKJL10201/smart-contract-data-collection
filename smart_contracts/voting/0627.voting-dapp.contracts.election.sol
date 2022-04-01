pragma solidity 0.5.16;

contract election {
	uint[3] private votes;
	mapping(address => bool) public voters;

	constructor() public {
		votes[0]=0;
		votes[1]=0;
		votes[2]=0;
	}
	
	function castVote(uint id) public {

		require(!voters[msg.sender]);

		voters[msg.sender]=true;		
		
		if(id==0) {
			votes[0]+=1;	
		} else if(id==1) {
			votes[1]+=1;
		} else if(id==2) {
			votes[2]+=1;
		}
	}
	
	function viewVote() public view returns(uint[3] memory) {
		return(votes);
	}
}
