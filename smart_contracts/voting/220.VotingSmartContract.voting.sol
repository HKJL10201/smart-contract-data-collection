//SPDX-License-Identifier: APACHE

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
pragma solidity ^0.8.4;
contract Voting  {
    
    uint256 counter = 0;
    address public token;
    uint public minimumAmount;
    uint public airdropAmount;
    uint256 public startTime;
    uint256 public endTime;
    address owner;
    struct Project {
        uint256 id;
        string name;
        string category;
        string uri;
        string description;
        uint accumulatedTokenBalance;


        uint256 totalVotes;
        address[] alreadyVotedAddress;
    }
 modifier onlyOwner{
        require(msg.sender==owner,"only owner can do this ");
        _;
    }
    mapping(uint256 => Project) public projects;
    
    Project[] public projectCollect;
    constructor(uint _airdropAmount,address _token,uint _minimumAmount,uint _startTime,uint _endTime){
        require(_startTime <= _endTime, "start time should  not be greater then endtime");
        require(block.timestamp <= _startTime, "start time should not be greater then endtime");
        airdropAmount=_airdropAmount;
        token = _token;
        minimumAmount=_minimumAmount;
        startTime=_startTime;
        endTime=startTime + (_endTime * 1 minutes);
        owner = msg.sender;


    }
    

    
    // function startVoting(uint _time) public {
    //     startTime = block.timestamp;
    //     endTime = startTime + (_ime * 1 minutes);
    // }
    function getVotedAddress(uint _projectId)public view returns (address[] memory){

        return projects[_projectId].alreadyVotedAddress;

    }
    function addCandidate(string memory _name,string memory _category,string memory _uri,string memory _description) public onlyOwner {
        require(projectCollect.length > 3, "Max 3 Candidates can be there in the election");
        
        counter = counter + 1;
        uint256 _uniqueId = counter;
        projects[_uniqueId].id = _uniqueId;
        projects[_uniqueId].name = _name;
        projects[_uniqueId].category=_category;
        projects[_uniqueId].uri=_uri;
        projects[_uniqueId].description=_description;
        projectCollect.push(projects[_uniqueId]);
    }
    function candidateList() public view returns(uint){
        return projectCollect.length;
    }

    function vote(uint256 _projectId) public {
        // Check if voting is happening within 10 minutes or after 10 minutes.
        require(IERC20(token).balanceOf(msg.sender)>=minimumAmount,"your token balance is lesser then minimum amount required to participate");
        require(block.timestamp > endTime, "Voting Time expired. Voting was only for 10 minutes.");
        
        require(projects[_projectId].id != 0, "No candidate present with this id");
        
        bool _isAlreadyVoted = false;
        Project memory _project = projects[_projectId];
        for(uint i = 0; i < _project.alreadyVotedAddress.length; i++) {
            if(_project.alreadyVotedAddress[i] == msg.sender) {
                _isAlreadyVoted = true;
            }
        }
        require((_isAlreadyVoted == false && _project.alreadyVotedAddress.length <= 10), "Max 10 voters can vote to this candidate and same voter can't vote more than once."); 
        projects[_projectId].totalVotes += 1;
        
        projects[_projectId].alreadyVotedAddress.push(msg.sender);
        projects[_projectId].accumulatedTokenBalance +=IERC20(token).balanceOf(msg.sender);
    }
    
    function getCandidateInfo(uint _id) public view returns(string memory,string memory,string memory, string memory){
        //candidates[_id].name;
        return(projects[_id].name,projects[_id].category,projects[_id].uri,projects[_id].description);

    }
    function getCandidateVotes(uint _candidateId) public view returns(uint){

        require(block.timestamp < endTime, "you can not get Cap  before ending of poll");
        return projects[_candidateId].totalVotes;


    }
    function totalElectionCap(uint _winnerId)public view returns(uint){
        require(block.timestamp > endTime, "you can not get Cap  before ending of poll");
         return projects[_winnerId].accumulatedTokenBalance;

    }



    function getResult() public view returns(uint256) {
        // Check if result is declaring after 10 minutes or not.
        require(block.timestamp > endTime, "Result will be declared after 10 minutes of Voting.");
        
        uint256 _maxVotes = 0;
        uint256 _winnerId = 0;
        for(uint i = 0; i < projectCollect.length; i++) {
            _winnerId = (projects[i].totalVotes > _maxVotes) ? projectCollect[i].id : _winnerId;
            _maxVotes = (projectCollect[i].totalVotes > _maxVotes) ? projectCollect[i].totalVotes : _maxVotes;
        }
        
        return _winnerId;
    }
}
