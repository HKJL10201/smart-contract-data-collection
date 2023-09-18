// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 <0.9.0;

contract TweeterContract {
    struct Tweet{
        uint id;
        address author;
        string content;
        uint createdAt;
    }
    struct Message{
        uint id;
        string content;
        address from;
        address to;
        uint createdAt;
    }
    mapping(uint=>Tweet) public tweets;
    mapping(address => uint[]) public tweetsOf;
    mapping(uint => Message[]) public conversations;
    mapping(address => mapping(address => bool)) public operators;
    mapping(address => address[]) public following;

    uint nextid;
    uint nextMessageId;

    function _tweet(address _from, string memory _content) internal{
        require(_from == msg.sender || operators[_from][msg.sender],"You don't have access");
        tweets[nextid]= Tweet(nextid,_from,_content, block.timestamp);
        tweetsOf[_from].push(nextid);
        nextid = nextid+1;

    }
    function _sendMessage(address _from,address _to, string memory _content) internal{
        require(_from ==msg.sender || operators[_from][msg.sender], "You don't have access");
        conversations[_from].push(Message(nextMessageId,_content,_from,_to,block.timestamp));
        nextMessageId++;
    }
    function tweet(string memory _content) public {
        _tweet(msg.sender, _content);
    }
    function tweet(address _from, string memory _content) public{
        _tweet(_from,_content);
        
    }
    function sendMessage(string memory _content,address _to) public{
        _sendMessage(msg.sender,_to,_content);

    }
    function sendMessage(address _from,address _to,string memory _content) public{
        _sendMessage(_from,_to,_content);
    }
    function follow(address _followed) public{
        following[msg.sender].push(_followed);

    }
    function allow(address _operator) public{
        operators[msg.sender][_operator]=true;
    }
    function disallow(address _operator) public{
        operators[msg.sender][_operator]=false;

    }
    function getLatestTweets(uint count)public view returns(Tweet[]memory){
        require(count>0 && count<= nextid,"Count is not proper");
        Tweet[] memory _tweets = new Tweet[] (count);
        uint j;
        for(uint i= nextid-count;i<nextid; i++){
            Tweet storage _structure =tweets[i];
            _tweets[j]=Tweet(_structure.id,
            _structure.author,
            _structure.content,
            _structure.createdAt);
        j=j+1;
        }
    return _tweets;
    }
    function getLatestofUser(address _user,uint, uint count) public view returns(Tweet[] memory){
        Tweet[] memory _tweets = new Tweet[](count);
        uint[] memory ids = tweetsOf[_user];
        require(count>0 && count<ids.length,"Count is not defined");
        uint j;

    for(uint i =ids.length- count; i< ids.length;i++){
        Tweet storage _structure =tweets[ids[i]];
        _tweets[j]=Tweet(_structure.id,
            _structure.author,
            _structure.content,
            _structure.createdAt);
  
    j=j+1;
     
    } 

return _tweets;

    }
}
