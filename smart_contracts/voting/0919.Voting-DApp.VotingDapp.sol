pragma solidity ^0.5.0;
//because of the array of string passed as an argument in a function and the return of an array of structs
pragma experimental ABIEncoderV2;

contract VotingDapp {
    address public admin;
    uint nextBallotId;
    
    mapping (address => bool) public voters;
    mapping (uint => Ballot) ballots;
    mapping (address => mapping (uint => bool)) votes;
    
    struct Choice {
        uint id;
        string name;
        uint votes;
    }
    
    struct Ballot {
        uint id;
        string name;
        Choice[] choices;
        uint end;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin can make this call');
        _;
    }
    
    constructor() public {
        admin = msg.sender;
    }
    
    function addVoters(address[] calldata _voters) external onlyAdmin {
        for(uint i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }
    }
    
    function createBallot(string memory _name, string[] memory _choices, uint _offset) public onlyAdmin {
        ballots[nextBallotId].id = nextBallotId;
        ballots[nextBallotId].name = _name;
        ballots[nextBallotId].end = now + _offset;
        for(uint i = 0; i < _choices.length; i++) {
            ballots[nextBallotId].choices.push(Choice(i, _choices[i], 0));
        }
        nextBallotId++;
    }
    
    function vote(uint _ballotId, uint _choiceId) external {
        require(voters[msg.sender] == true, 'only approved voters can vote');
        require(votes[msg.sender][_ballotId] == false, 'cannot vote more than once per ballot');
        require(now < ballots[_ballotId].end, 'voting already ended');
        ballots[_ballotId].choices[_choiceId].votes++;
        votes[msg.sender][_ballotId] == true;
    }
    
    function results(uint _ballotId) view external returns(Choice[] memory){
        require(now > ballots[_ballotId].end, 'cannot view until voting ends');
        return ballots[_ballotId].choices;
    }
}