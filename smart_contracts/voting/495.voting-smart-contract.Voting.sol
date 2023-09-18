//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;


contract Voting{

    address public immutable i_owner;

    mapping(address=>mapping(uint=>bool)) public votes;

    mapping(address=>bool) public voters;
    struct Choice{
        uint256 id;
        string name;
        uint256 votes;
    }

    struct Ballot{
        uint256 id;
        string name;
        Choice[] choices;
        uint256 end;
    }

    mapping(uint256=>Ballot) ballots;
    uint256 nextBallotId;

    constructor() {
        i_owner=msg.sender;
    }

    function addVoters(address[] memory  _voters) external onlyAdmin {
            for(uint256 i=0;i<_voters.length;i++){
                voters[_voters[i]]=true;
            }
    }

    function createBallot(string memory name,string[] memory _choices,uint256 offset) external onlyAdmin {
            ballots[nextBallotId].id=nextBallotId;
            ballots[nextBallotId].name=name;
            ballots[nextBallotId].end = block.timestamp + offset;
            for(uint256 i=0;i<_choices.length;i++){
                ballots[nextBallotId].choices.push(Choice(i,_choices[i],0));
            }
            nextBallotId++;
       
    }

    function vote(uint256 ballotId,uint256 choiceId) external {
        require(voters[msg.sender]==true,"Only approved voter is allowed to vote");
        require(votes[msg.sender][ballotId]==false,"Already voted");
        require(ballots[ballotId].end>=block.timestamp,"Can only vote until ballot end date");
        ballots[ballotId].choices[choiceId].votes++;
        votes[msg.sender][ballotId]=true;
    }

    function results(uint256 ballotId) view external returns(Choice[] memory) {
        require(ballots[ballotId].end <block.timestamp,"Ballot hasn't ended yet");
        return ballots[ballotId].choices;
    }

    modifier onlyAdmin(){
        require(msg.sender==i_owner,"Only Admin allowed");
        _;
    }

}