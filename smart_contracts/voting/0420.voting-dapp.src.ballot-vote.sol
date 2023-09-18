pragma solidity >= 0.7.0 < 0.9.0;

contract Ballot {
    
	struct Voter {
        
		uint vote;
		bool voted;
		uint weight;
	}
    
	struct Proposal {

		bytes32 name;   // the name of each proposal
		uint voteCount; // number of accummulated votes
	}
    
	Proposal [] public proposals;
    
	// mapping allows for us to create a store value with keys and indexes
	mapping(address => Voter) public voters; // voters get address as a key and Voter for value
    
	address public chairperson;
    
	// memory defines a temporary data location in Solidity during runtime 
	constructor(bytes32 [] memory proposalNames) {
        
		chairperson = msg.sender;

		voters[chairperson].weight = 1;
        
		// add the proposal names to the smart contract upon deployment
		for (uint i = 0; i < proposalNames.length; i++) {
			proposals.push(Proposal({
				name: proposalNames[i],
				voteCount: 0
			}));
		}
	}
    
	function giveRightToVote(address voter) public {
		require(msg.sender == chairperson, 'Only the Chairperson can give access to vote');
		require(!voters[voter].voted, 'The voter has already voted');
		require(voters[voter].weight == 0);
        
		voters[voter].weight = 1;
	}
    
	function vote(uint proposal) public {
        
		Voter storage sender = voters[msg.sender];
		require(sender.weight != 0, 'Has no right to vote');
		require(!sender.voted, 'Already voted');
        
		sender.voted == true;
		sender.vote = proposal;
        
		proposals[proposal].voteCount += sender.weight;
	} 
    
	function winningProposal() public view returns (uint _winningProposal) {
        
		uint winningVoteCount = 0;
        
		for (uint i = 0; i < proposals.length; i++) {
			if (proposals[i].voteCount > winningVoteCount) {
				winningVoteCount = proposals[i].voteCount;
				_winningProposal = i;        
			}
		}
	}
    
	function winningName() public view returns (bytes32 _winningName) {
		_winningName = proposals[winningProposal()].name;
	}
}
