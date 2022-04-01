pragma solidity 0.7.5;
pragma abicoder v2;

contract Admin{
    
    struct Poll{
        uint pollId;
        string pollDetails;
        uint256 creationTime;
        uint256 expirationTime; // in days
        uint voters;
        int votes;
        int result; //calculated as votes/voters
    }
    Poll [] polls;
    address admin;
    
    constructor(){
        admin = msg.sender;
    }
    modifier onlyAdmin{
        require(msg.sender == admin,'Accessible by Admin only');
        _;
    }
    
    mapping(uint => Poll)pollLogs; //pollId => poll
    
    event PollCreated(address creator,uint pollId, string pollDetails, uint validityInDays);
    
    //validityTime - Validity in terms of days
    function createPoll(string memory _pollDetails,uint validityTime) public onlyAdmin{
        Poll memory p = Poll(polls.length,_pollDetails,block.timestamp,block.timestamp + (validityTime * 1 days),0,0,0);
        pollLogs[p.pollId] = p;
        polls.push(p);
        emit PollCreated(admin,p.pollId,_pollDetails,validityTime);
    }
    
    function viewPoll(uint _pollId) public view returns(Poll memory){
        return pollLogs[_pollId];
    } 
    
    function getAllPolls() public view returns(Poll [] memory){
        return polls;
    }
    
    function pollResult(uint _pollId) public view returns(string memory){
        require(pollLogs[_pollId].voters != 0,'No one has voted in this poll');
        require(block.timestamp > pollLogs[_pollId].expirationTime,'Poll result can not be declared before due date');
         return  pollLogs[_pollId].result > 0 ?'Accepted':'Rejected';
         
    }
}
