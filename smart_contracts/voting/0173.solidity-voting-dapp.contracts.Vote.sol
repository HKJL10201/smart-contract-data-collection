pragma solidity 0.8.7;

contract Vote {
    address _owner;

    mapping(uint256 => mapping(address => bool)) votes;
    mapping(address => bool) authorities;
    mapping(address => mapping(address => bool)) public delegates;

    uint256 proposalCnt;
    struct Proposal {
        bytes32 name;
        address creator;
        uint256 createdAt;
    }
    mapping(uint256 => Proposal) public proposals;

    event OwnerTransfered(address indexed _prvious, address indexed _new);
    event ProposalCreated(address indexed _creator, bytes32 _newProposal, uint256 createdAt);
    event ProposalVoted(uint256 _proposalID, address indexed _voter, address indexed _from, uint256 createdAt);
    event VoteDelegated(address indexed _from, address indexed _to);
    event CancelDelegate(address indexed _from, address indexed _to);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: this user is not the owner");
        _;
    }

    function transferOwner(address _newOwner) public onlyOwner() {
        require(_newOwner != address(0), "This address can not be owner");

        emit OwnerTransfered(_owner, _newOwner);

        _owner = _newOwner;
    }

    function addAuthor(address _newAuthor) public  onlyOwner() {
        require(_newAuthor != address(0), "This author is invalid");

        authorities[_newAuthor] = true;
    }

    function createProposal(bytes32 _newProposal) public {
        uint256 timestamp = block.timestamp;
        proposals[proposalCnt] = Proposal(_newProposal, msg.sender, timestamp);
        proposalCnt++;

        emit ProposalCreated(msg.sender, _newProposal, timestamp);
    }

    function vote(uint256 _proposalID, address _voter) public {
        require(_proposalID <= proposalCnt, "Invalid porposal");

        require(authorities[msg.sender], "Not authorized to vote");

        require(_voter == msg.sender || delegates[msg.sender][_voter], "You dont have delegation");

        require(!votes[_proposalID][_voter], "Voted already!");
        
        votes[_proposalID][_voter] = true;
        emit ProposalVoted(_proposalID, _voter, msg.sender, block.timestamp);
    }

    function delegate(address _to) public {
        require(msg.sender != _to, "Can not delegate to same address");

        delegates[_to][msg.sender] = true;
        emit VoteDelegated(msg.sender, _to);
    }

    function cancelDelegate(address _to) public {
        require(msg.sender != _to, "Can not cancel yourself");

        require(delegates[_to][msg.sender], "He is not delegated user");

        delegates[_to][msg.sender] = false;
        emit CancelDelegate(msg.sender, _to);
    }
}
