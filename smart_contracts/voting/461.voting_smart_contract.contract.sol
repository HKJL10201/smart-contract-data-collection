pragma solidity ^0.8.6;

contract PollContract{
    
    struct Poll{
        uint256 id;
        string question;
        string thumbnail;
        uint32[] votes;
        string[] options;
    }
    
    struct Voter{
        address id;
        uint256[] votedIds;
        mapping(uint256 => bool) votedMap;
    }
    
    Poll[] private polls;
    mapping(address => Voter) private voters;
    
    function createPoll(string memory _question, string memory _thumbnail, string[] memory _options) public {
        
        require(bytes(_question).length > 0, "Question Cannot Be Empty");
        require(_options.length > 0, "Question Cannot Be Empty");
        
        //Assigning Ids
        uint256 pollId = polls.length;
        
        Poll memory newPoll = Poll({
            id: pollId,
            question: _question,
            thumbnail: _thumbnail,
            options: _options,
            votes: new uint32[](_options.length)
        });
        
        polls.push(newPoll);
        
        
    }
    
    function getPolls() external view returns(Poll[] memory){
        return polls;
    }
    
    function getPollById(uint256 _id) external view returns(uint256, string memory, string memory, uint32[] memory, string[] memory){
        require(_id < polls.length && _id
         >= 0,"No Poll Found");
         
        return (
            polls[_id].id,
            polls[_id].question,
            polls[_id].thumbnail,
            polls[_id].votes,
            polls[_id].options
            );
    }
    
    function vote(uint256 _pollId,uint32 _vote) external {
        require(_pollId < polls.length, "Poll doesn't exist");
        require(_vote < polls[_pollId].options.length, "Invalid vote");
        require(voters[msg.sender].votedMap[_pollId] == false, "You already voted");
        
        //Vote
        polls[_pollId].votes[_vote] += 1;
        voters[msg.sender].votedIds.push(_pollId);
        voters[msg.sender].votedMap[_pollId] = true;
        
    }
    
    function getVoter(address _id) external view returns(address, uint256[] memory) {
        return (
            voters[_id].id,
            voters[_id].votedIds
            );
    }
    
    function getTotalPolls() external view returns(uint256) {
        return polls.length;
    }
    
}