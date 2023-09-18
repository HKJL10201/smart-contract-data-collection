pragma solidity 0.5.8;

// Modified contract for testing

pragma solidity 0.5.8;

contract TestContract {
// MODIFIED PART
	modifier requireEnded {
		require(!OPEN, "Unavailable until voting period ends");
		_;
	}

	modifier requireOpen {
		require(OPEN, "Voting period must be open");
		_;
	}

	function votingOpen() public view returns (bool) {
		uint256 time = now;
		return time < votingEnd;
	}

	function votingOn() public {
		OPEN = true;
	}

	function votingOff() public {
		OPEN = false;
	}

	bool public OPEN;
// the rest is unchanged

	// model a proposal
	struct Proposal {
		uint256 id;
		uint256 directVotes;
		uint256[] curators;
	}

	struct ProposalTotalVoteCount {
		uint256 id;
		uint256 votes;
	}

	// model a curator
	struct Curator {
		uint256 votes;
		address addr;
	}

	// number of proposals
	uint256[] public proposalsIds;
	// store proposals info
	mapping(uint256 => Proposal) public proposals;
	// store curators info
	mapping(uint256 => Curator) public curators;
	// store addresses of curators
	mapping(address => uint256) public curatorsIds;
	// store accounts that have voted or delegated
	mapping(address => bool) public voteSpent;	
	// time for voting to start
	uint256 public votingStart;
	// time for voting to end
	uint256 public votingEnd;

	constructor(
		uint256[] memory _proposalsIds,
		uint256 _votingStart,
		uint256 _votingEnd
	) public {
		// require that voting starting time is not before the deployment time
		require(_votingStart >= now, "Starting time can't be less than 'now'");

		// require that ending time is greater than the starting time
		require(_votingEnd > _votingStart, "Ending time has to come latter than starting");

		// require that there are at least two proposals
		require(_proposalsIds.length >= 2, "There should be at least two proposals");

		for(uint256 i = 0; i < _proposalsIds.length; i++) {
			// require that no id is set to zero
			require(_proposalsIds[i] != 0, "'0' is an invalid proposal id");
			proposals[_proposalsIds[i]] = Proposal(_proposalsIds[i], 0, new uint256[](0));
		}

		proposalsIds = _proposalsIds;
		votingStart = _votingStart;
		votingEnd = _votingEnd;
	}

	// curator registered
	event curatorRegistered(uint256 indexed curatorId);

	// vote delegated to curator
	event voteDelegated(uint256 indexed curatorId, address indexed voter);

	// direct vote cast
	event directVote(uint256 indexed proposalId, address indexed voter);

	// curator vote cast
	event curatorVote(uint256 indexed proposalId, uint256 indexed curatorID);

	// require that message sender hasn't already voted
	modifier requireVoteNotSpent {
		require(!voteSpent[msg.sender], "Vote have already been spent");
		_;
	}

	// gets an id and return whether of not it is an proposal id
	function isProposalId(uint256 _id) public view returns (bool) {
		if(_id == 0) return false;
		return proposals[_id].id != 0;
	}

	// gets an id and return whether of not it is a curator id
	function isCuratorId(uint256 _id) public view returns (bool) {
		if(_id == 0) return false;
		return curators[_id].addr != address(0);
	}

	// gets an address and return whether of not it is an curator address
	function isCuratorAddress(address _addr) public view returns (bool) {
		if(_addr == address(0)) return false;
		return curatorsIds[_addr] != 0;
	}

	// register as a curator
	function registerAsCurator(uint256 _id) external requireOpen requireVoteNotSpent{
		// require a valid id
		require(_id != 0, "'0' is an invalid id");

		// require that address is not already registered
		require(!isCuratorAddress(msg.sender), "Can't register more than once");

		// require that id is not already used
		require(!isCuratorId(_id), "Id already being used");

		curators[_id] = Curator(1, msg.sender);
		curatorsIds[msg.sender] = _id;

		// trigger candidate registration event
		emit curatorRegistered(_id);
	}

	// delegate the vote to an registered curator
	function delegateVote(uint256 _curatorId) external requireOpen requireVoteNotSpent{
		// require that message sender is not a curator himself
		require(!isCuratorAddress(msg.sender), "Curators can't delegate their votes");

		// require that id is not '0'
		require(_curatorId != 0, "'0' is an invalid id");

		// require a valid curator ID
		require(isCuratorId(_curatorId), "Id does not correspond to any curator");

		// recording the expenditure of the vote
		voteSpent[msg.sender] = true;		

		// recording the vote
		curators[_curatorId].votes++;

		// trigger vote delegation event
		emit voteDelegated(_curatorId, msg.sender);	
	}

	// voting function for both curators and independent voters
	function vote(uint256 _proposalId) external requireOpen requireVoteNotSpent{
		// require a valid proposal ID
		require(isProposalId(_proposalId), "Invalid proposal id");

		// recording the expenditure of the vote
		voteSpent[msg.sender] = true;		

		if(isCuratorAddress(msg.sender)) {
			proposals[_proposalId].curators.push(curatorsIds[msg.sender]);
			emit curatorVote(_proposalId, curatorsIds[msg.sender]);
		} else {
			proposals[_proposalId].directVotes++;
			// trigger voted event
			emit directVote(_proposalId, msg.sender);
		}
	}

	// gets a proposal id and returns the list of curators that have voted on it
	function getProposalCurators(uint256 _proposalId) external view returns(
		uint256[] memory
	) {
		require(isProposalId(_proposalId), "Invalid proposal id");
		return proposals[_proposalId].curators;
	}	

	//  Returns the list of proposals and the list of total votes
	//  The element i of the list of votes correspond to the proposal i
	// of the proposals list
	function results() external view requireEnded returns (
		uint256[] memory _proposalsIds,
		uint256[] memory _totalVotes
	) {
		_proposalsIds = proposalsIds;
		uint256[] memory _total = new uint256[](proposalsIds.length);
		for(uint256 i = 0; i < proposalsIds.length; i++) {
			_total[i] = voteCount(proposalsIds[i]);
		}
		_totalVotes = _total;
	}

	// 	Receives an id and returns the final vote count of the correspondent
	// proposal
	function voteCount(uint256 _proposalId)
		public view requireEnded returns (uint256 _voteCount) {
		// require that id is valid
		require(isProposalId(_proposalId), "Invalid proposal id");

		_voteCount = proposals[_proposalId].directVotes;

		uint256[] memory _curators = proposals[_proposalId].curators;
		for(uint256 j = 0; j < _curators.length; j++) {
			_voteCount += curators[_curators[j]].votes;
		}
	}
}