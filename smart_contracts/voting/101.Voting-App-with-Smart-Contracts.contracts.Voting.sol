pragma solidity ^0.5.6;
    contract Voting {
     struct Ballot{
        uint id;
        uint upVote;
        uint downVote;
        mapping(address => bool) voters;
    }
    uint[] private ballotListKeys;
    mapping(uint => Ballot) private ballotList;
    mapping(uint => bool) private ballotListStatus;
    

    function addAnswer ( uint256 ballotKey, uint256 vote ) external returns ( bool success ){
        require(ballotListStatus[ballotKey]);
        require(!ballotList[ballotKey].voters[msg.sender]);
        if(vote == 1) {
            ballotList[ballotKey].upVote += 1;
            ballotList[ballotKey].voters[msg.sender] = true;
            
        }else if(vote == 0){
            ballotList[ballotKey].downVote += 1;
            ballotList[ballotKey].voters[msg.sender] = true;

        }else{
            return false;
        }
        return true;
    }
  function getBallot ( uint256 ballotKey ) external view returns ( uint256 id, uint256 upVote, uint256 downVote ) {
      require(ballotListStatus[ballotKey]);
      uint ballotId = ballotList[ballotKey].id;
      uint ballotUpVote = ballotList[ballotKey].upVote;
      uint ballotDownVote =  ballotList[ballotKey].downVote;
      return(ballotId,ballotUpVote,ballotDownVote);
       
  }
  function getBallotAnswerCount ( uint256 ballotKey ) external view returns ( uint256 answerCount ){
      require(ballotListStatus[ballotKey]);
      return ballotList[ballotKey].upVote + ballotList[ballotKey].downVote;
  }
  function getBallotCount (  ) external view returns ( uint256 ){
      return ballotListKeys.length;
      
  }
  function getballotListKeys (  ) external view returns ( uint256[] memory ){
      
      return ballotListKeys;
      
  }
  function newBallot ( uint ballotKey ) onlyStatusTrue(ballotKey) public returns ( bool success ){
      ballotList[ballotKey].id = ballotKey;
      ballotListKeys.push(ballotKey);
      ballotListStatus[ballotKey] = true;
      return true;
      
      
  }
    modifier onlyStatusTrue(uint ballotKey) {
        require(!ballotListStatus[ballotKey]);
        _;
    }
   }