pragma solidity 0.5.1;


contract VotingContract {
    
    string public question;
    address public category;
    bytes32[] public options;
    uint256 public votingEndTime;
    uint256 public resultsEndTime;
    bool public isPrivate;
    mapping(address => bool) internal permissions;
    mapping(address => bool) public hasVoted;
    uint256[] internal votes;

    modifier hasPermission(address user) {
        require(!isPrivate || (isPrivate && permissions[user]), "You don't have voting permission");
        _;
    }
    
    modifier isInVotingState() {
        require(now <= votingEndTime, "It's too late to vote");
        _;
    }
    
    modifier isInResultsState() {
        require(now <= resultsEndTime && now > votingEndTime, "You cannot see the results right now");
        _;
    }
    
    // TODO: Do we need some creator requirements?
    constructor(string memory _question,
        address _category,
        bytes32[] memory _options,
        uint256 _votingEndTime,
        uint256 _resultsEndTime,
        bool _isPrivate,
        address[] memory _permissions) public {

        require(_votingEndTime >= now + 20, "Voting end time has to be somewhere in the future (at least 20s from now)");
        require(_resultsEndTime >= _votingEndTime + 20, "Results end time has to be later than voting end time (at least 20s)");
        require(_options.length >= 2, "You cannot create a ballot without at least 2 options");
                    
        question = _question;
        category = _category;
        options = _options;
        votingEndTime = _votingEndTime;
        resultsEndTime = _resultsEndTime;
        isPrivate = _isPrivate;
        for (uint i = 0; i < _permissions.length; i++) {
            permissions[_permissions[i]] = true;
        }
        votes.length = _options.length;
    }

    function vote(uint _option) public 
                                    hasPermission(msg.sender)
                                    isInVotingState() {
        require(!hasVoted[msg.sender], "You have already voted");
        votes[_option]++;
        hasVoted[msg.sender] = true;
    }
    
    function numberOfOptions() public view returns(uint) {
        return options.length;
    }

    function viewVotes() public view returns(uint256[] memory) {
        require(now >= votingEndTime, "It's too early to see the votes");
        require(now < resultsEndTime, "It's too late to see the votes");
        return votes;
    }

    function viewContractInfo() public view returns(string memory, address, bytes32[] memory, uint256, uint256) {
        return (question, category, options, votingEndTime, resultsEndTime);
    }
    
    function isPrivileged(address user) public view returns(bool) {
        return permissions[user];
    }
}