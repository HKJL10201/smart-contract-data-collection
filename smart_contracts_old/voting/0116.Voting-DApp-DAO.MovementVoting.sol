/**
  * The Movement
  * Decentralized Autonomous Organization
  */
  
pragma solidity ^0.4.18;

contract MVT {
    function balanceOf(address addr) returns (uint);
}

contract MovementVoting {
    mapping(address => int256) public votes;
    address[] public voters;
    uint256 public endBlock;
	address public admin;
	
	MVT token;
	uint minTokenAmountToVote=100;
	string urlVotingDetails;
	
    event onVote(address indexed voter, int256 indexed proposalId);
    event onUnVote(address indexed voter, int256 indexed proposalId);

    function MovementVoting(uint256 _endBlock, uint _minTokenAmountToVote, string _urlVotingDetails) {
        endBlock = _endBlock;
		admin = msg.sender;
		minTokenAmountToVote =_minTokenAmountToVote;
		urlVotingDetails = _urlVotingDetails;
		token = MVT(0x89eebb3ca5085ea737cc193b4a5d5b2b837ce548);
    }

	function changeEndBlock(uint256 _endBlock)
	onlyAdmin {
		endBlock = _endBlock;
	}

    function vote(int256 proposalId) {
        
        uint balance = token.balanceOf(msg.sender)/(10 ** 18);
        
        require(balance >= minTokenAmountToVote);
        require(msg.sender != address(0));
        require(proposalId > 0);
        require(endBlock == 0 || block.number <= endBlock);
        if (votes[msg.sender] == 0) {
            voters.push(msg.sender);
        }

        votes[msg.sender] = proposalId;

        onVote(msg.sender, proposalId);
    }

    function unVote() {

        require(msg.sender != address(0));
        require(votes[msg.sender] > 0);
        int256 proposalId = votes[msg.sender];
		votes[msg.sender] = -1;
        onUnVote(msg.sender, proposalId);
    }

    function votersCount()
    constant
    returns(uint256) {
        return voters.length;
    }
    
    function voteUrlInfo()
    constant
    returns(string) {
        return urlVotingDetails;
    }

    function getVoters(uint256 offset, uint256 limit)
    constant
    returns(address[] _voters, int256[] _proposalIds) {

        if (offset < voters.length) {
            uint256 resultLength = limit;
            uint256 index = 0;

         
            if (voters.length - offset < limit) {
                resultLength = voters.length - offset;
            }

            _voters = new address[](resultLength);
            _proposalIds = new int256[](resultLength);

            for(uint256 i = offset; i < offset + resultLength; i++) {
                _voters[index] = voters[i];
                _proposalIds[index] = votes[voters[i]];
                index++;
            }

            return (_voters, _proposalIds);
        }
    }

	modifier onlyAdmin() {
		if (msg.sender != admin) revert();
		_;
	}
}
