pragma solidity >=0.4.21 <0.7.0;
pragma experimental ABIEncoderV2;

contract Voting {
    address public creator;
    uint32 public electionCount = 0;
    uint32 public aspirantCount = 0;

    struct Election {
        uint32 electionId;
        string name;
        uint32 start_timestamp;
        uint32 end_timestamp;
        uint32 voteCount;
        uint32 teamCount;
        uint32 tokenCount;
        bool ended;
        uint32[] teamIds; // apparently, you can't loop over mappings or their keys
        mapping(uint32 => Team) teams;
        mapping(bytes32 => Ballot) votingTokens;
    }

    struct Aspirant {
        uint32 aspirantId;
        string name;
    }

    struct Team {
        uint32 teamId;
        string name;
        uint32 chairmanId;
        uint32 secGenId;
        uint32 treasurerId;
        uint32 votes;
    }

    struct Ballot {
        uint32 teamId;
        bytes32 votingToken; // a hash of the actual voting token
        bool cast;
    }

    mapping(uint32 => Election) public elections;
    mapping(uint32 => Aspirant) public aspirants;

    event Cast(uint32 _electionId, uint32 _teamId, uint32 teamCount, uint32 totalCount, uint castAt);
    event ElectionEnded(uint32 _electionId, uint32 _winningTeamId);

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the Creator can call this.");
        _;
    }

    modifier notZero(uint32 _n) {
        require(_n != 0, "IDs should not equal zero.");
        _;
    }

    modifier electionExists(uint32 _electionId) {
        require(elections[_electionId].electionId == _electionId, "Election does not exist.");
        _;
    }


    constructor() public {
        creator = msg.sender;
    }

    function setElection(uint32 _electionId, string memory _name, uint32 _start_timestamp, uint32 _end_timestamp)
    public
    onlyCreator()
    notZero(_electionId)
    {
        uint time = now;
        if (elections[_electionId].electionId == _electionId) {
            require(time < elections[_electionId].start_timestamp, "Election has either started or ended.");
            elections[_electionId].name = _name;
            elections[_electionId].start_timestamp = _start_timestamp;
            elections[_electionId].end_timestamp = _end_timestamp;
        } else {
            uint32[] memory teamIds;
            elections[_electionId] = Election(_electionId, _name, _start_timestamp, _end_timestamp, 0, 0, 0, false, teamIds);
            electionCount++;
        }
    }

    function setAspirant(uint32 _aspirantId, string memory _name)
    public
    onlyCreator()
    notZero(_aspirantId)
    {
        if (aspirants[_aspirantId].aspirantId == _aspirantId) {
            aspirants[_aspirantId].name = _name;
        } else {
            aspirants[_aspirantId] = Aspirant(_aspirantId, _name);
            aspirantCount++;
        }
    }

    function setTeam(uint32 _electionId, uint32 _teamId, string memory _name, uint32 _chairmanId, uint32 _secGenId, uint32 _treasurerId)
    public
    onlyCreator()
    notZero(_electionId)
    electionExists(_electionId)
    notZero(_teamId)
    {
        uint time = now;
        require(time < elections[_electionId].start_timestamp, "Election has either started or ended.");
        require(aspirants[_chairmanId].aspirantId == _chairmanId, "ChairmanID does not exist in our records.");
        require(aspirants[_secGenId].aspirantId == _secGenId, "Secretary General ID does not exist in our records.");
        require(aspirants[_treasurerId].aspirantId == _treasurerId, "TreasurerID does not exist in our records.");
        if (elections[_electionId].teams[_teamId].teamId == _teamId) {
            elections[_electionId].teams[_teamId].name = _name;
            elections[_electionId].teams[_teamId].chairmanId = _chairmanId;
            elections[_electionId].teams[_teamId].secGenId = _secGenId;
            elections[_electionId].teams[_teamId].treasurerId = _treasurerId;
        } else {
            elections[_electionId].teamIds.push(_teamId);
            elections[_electionId].teams[_teamId] = Team(_teamId, _name, _chairmanId, _secGenId, _treasurerId, 0);
            elections[_electionId].teamCount++;
        }
    }

    function setVotingToken(uint32 _electionId, string memory _token)
    public
    onlyCreator()
    notZero(_electionId)
    {
        bytes32 _hashedToken = keccak256(abi.encode(_token));
        require(elections[_electionId].votingTokens[_hashedToken].votingToken != _hashedToken, "Voting token already added.");
        uint32 tokenCount = elections[_electionId].tokenCount;
        elections[_electionId].votingTokens[_hashedToken] = Ballot(tokenCount, _hashedToken, false);
        elections[_electionId].tokenCount++;
    }

    function cast(uint32 _electionId, uint32 _teamId, string memory _votingToken)
    public
    notZero(_electionId)
    notZero(_teamId)
    electionExists(_electionId)
    {
        setVotingToken(_electionId, _votingToken);
        uint time = now;
        require(time >= elections[_electionId].start_timestamp && time <= elections[_electionId].end_timestamp, "Not the time to cast votes.");
        bytes32 _hashedToken = keccak256(abi.encode(_votingToken));
        require(elections[_electionId].votingTokens[_hashedToken].votingToken == _hashedToken, "Voting token does not exist.");
        require(!elections[_electionId].votingTokens[_hashedToken].cast, "Voter has already cast their vote.");
        require(elections[_electionId].teams[_teamId].teamId == _teamId, "Team does not exist.");

        // register the vote
        elections[_electionId].votingTokens[_hashedToken].teamId = _teamId;
        elections[_electionId].votingTokens[_hashedToken].cast = true;
        elections[_electionId].teams[_teamId].votes++;
        elections[_electionId].voteCount++;
        emit Cast(_electionId, _teamId, elections[_electionId].teams[_teamId].votes,  elections[_electionId].voteCount, time);
    }

    function endElection(uint32 _electionId)
    public
    onlyCreator()
    notZero(_electionId)
    electionExists(_electionId)
    {
        require(now > elections[_electionId].end_timestamp, "Election not over.");
        require(!elections[_electionId].ended, "endElection has already been called.");
        elections[_electionId].ended = true;
        emit ElectionEnded(_electionId, getWinner(_electionId));
    }

    function getWinner(uint32 _electionId)
    public
    notZero(_electionId)
    electionExists(_electionId)
    view returns (uint32 _winningTeamId)
    {
        require(elections[_electionId].ended, "Election not over.");
        uint32 winningVoteCount = 0;
        uint32 _teamId;
        for (uint32 _i = 0; _i < elections[_electionId].teamIds.length; _i++) {
            _teamId = elections[_electionId].teamIds[_i];
            if (elections[_electionId].teams[_teamId].votes > winningVoteCount) {
                winningVoteCount = elections[_electionId].teams[_teamId].votes;
                _winningTeamId = _teamId;
            }
        }
    }

    function getTeam(uint32 _electionId, uint32 _teamId)
    public
    notZero(_electionId)
    electionExists(_electionId)
    view returns (uint32 teamId, string memory name, uint32 chairmanId, uint32 secGenId, uint32 treasurerId, uint32 votes)
    {
        require(elections[_electionId].teams[_teamId].teamId == _teamId, "Team does not exist.");
        Team memory t = elections[_electionId].teams[_teamId];
        return (t.teamId, t.name, t.chairmanId, t.secGenId, t.treasurerId, t.votes);
    }

    function getBallot(uint32 _electionId, string memory _token)
    public
    notZero(_electionId)
    electionExists(_electionId)
    view returns (uint32 teamId, bytes32 votingToken, bool voted)
    {
        bytes32 _hashedToken = keccak256(abi.encode(_token));
        require(elections[_electionId].votingTokens[_hashedToken].votingToken == _hashedToken, "Voting Token does not exist.");
        Ballot memory b = elections[_electionId].votingTokens[_hashedToken];
        return (b.teamId, b.votingToken, b.cast);
    }

    function getResults(uint32 _electionId)
    public
    notZero(_electionId)
    electionExists(_electionId)
    view returns (Team[] memory)
    {
        Team[] memory teams = new Team[](elections[_electionId].teamIds.length);
        uint32 _teamId;
        for (uint32 _i = 0; _i < elections[_electionId].teamIds.length; _i++) {
            _teamId = elections[_electionId].teamIds[_i];
            teams[_i] = elections[_electionId].teams[_teamId];
        }
        return teams;
    }
}
