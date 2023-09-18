// The Proposal contract
contract Proposal {
  string public text;
  uint public voteCount;
  address public creator;
  mapping(address => bool) public voters;

  constructor(string memory _text) {
    text = _text;
    creator = msg.sender;
  }

  function vote() public {
    require(voters[msg.sender] == false);
    voters[msg.sender] = true;
    voteCount++;
  }
}

// The Governance contract
contract Governance {
  address public admin;
  uint public proposalCount;
  mapping(uint => Proposal) public proposals;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function createProposal(string memory _text) public onlyAdmin {
    proposals[proposalCount] = new Proposal(_text);
    proposalCount++;
  }

  function voteOnProposal(uint _proposalIndex) public {
    Proposal proposal = proposals[_proposalIndex];
    proposal.vote();
  }

  function getProposalVoteCount(uint _proposalIndex) public view returns (uint) {
    Proposal proposal = proposals[_proposalIndex];
    return proposal.voteCount();
  }

}
