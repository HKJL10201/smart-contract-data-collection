pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

contract Voting {
    mapping(address => bool) public voters;
    struct Choice {
        uint256 id;
        string name;
        uint256 votes;
    }
    struct Ballot {
        uint256 id;
        string name;
        Choice[] choices;
        uint256 end;
    }
    mapping(uint256 => Ballot) public ballots;
    uint256 nextBallotId;
    address public admin;
    mapping(address => mapping(uint256 => bool)) votes;

    constructor() public {
        admin = msg.sender;
    }

    function addVoters(address[] calldata _voters) external onlyAdmin {
        for (uint256 i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }

    function createBallot(
        string memory name,
        string[] memory _choices,
        uint256 offset
    ) public onlyAdmin {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = name;
        ballots[nextBallotId].end = now + offset;
        for (uint256 i = 0; i < _choices.length; i++) {
            ballots[nextBallotId].choices.push(Choice(i, _choices[i], 0));
        }
        nextBallotId++;
    }

    function vote(uint256 ballotId, uint256 choiceId) external {
        require(voters[msg.sender] == true, "only voters can vote");
        require(
            votes[msg.sender][ballotId] == false,
            "voter can only vote once for a ballot"
        );
        require(
            now < ballots[ballotId].end,
            "can only vote until ballot end date"
        );
        votes[msg.sender][ballotId] = true;
        ballots[ballotId].choices[choiceId].votes++;
    }

    //If `pragma experimental ABIEncoderV2`
    function results(uint256 ballotId) external view returns (Choice[] memory) {
        require(
            now >= ballots[ballotId].end,
            "cannot see the ballot result before ballot end"
        );
        return ballots[ballotId].choices;
    }

    //If no `pragma experimental ABIEncoderV2`
    //function results(uint ballotId)
    //  view
    //  external
    //  returns(uint[] memory, string[] memory, uint[]memory) {
    //  require(now >= ballots[ballotId].end, 'can only see result after ballot end');
    //  Choice[] storage choices = ballots[ballotId].choices;
    //  uint[] memory ids = new uint[](choices.length);
    //  string[] memory names = new string[](choices.length);
    //  uint[] memory votes = new uint[](choices.length);
    //  for(uint i = 0; i < choices.length; i++) {
    //    ids[i] = choices[i].id;
    //    names[i] = choices[i].name;
    //    votes[i] = choices[i].votes;
    //  }
    //  return(ids, names, votes);
    //}

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
}
