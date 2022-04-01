pragma solidity ^0.4.17;

contract Claim {
  

  // struct Cow {
  //  uint cowId; //eg.666666
  //  uint birthday; //eg.180822
  //  address farmerId;
  // }

  struct Request {
    uint cowId;
    uint date; 
    // uint requestId;
        address farmer;
    // address vet;
    // address insurance;
    // uint state; // 0:to be check, -1:unhealthy, 1:healthy
    // uint reply; //0:to be reply, -1:rejected, 1:accepted
    // uint checkdate;//0 to be check
    // uint replydate;//0 to be reply
  }

    struct CheckedRequest {
        Request request;
        bool is_sick;
        uint checkdate;
        address vet;
    }

    struct ReplyedRequest {
        CheckedRequest checkedRequest;
        bool is_accepted;
        uint replydate;
        address insurance;
    }

  // mapping(uint => Cow) public Cows;

  mapping(uint => Request) public Requests; 
    mapping(uint => CheckedRequest) public CheckedRequests; 
    mapping(uint => ReplyedRequest) public ReplyedRequests; 

    uint[] public Requesthistory; // No.0
    uint[] public TobeCheck; //No.1
    uint[] public TobeReply; //No.2

  // function registerCow(uint cowId, uint birthday) public return (uint) {
  //  require(Cows[cowId] == 0);
  //  Cows[cowId] = cow(cowId, birthday, msg.sender);
  //  return cowId; 
  // }



  function initRequest(uint cowId, uint date) public returns (uint) {
    uint requestId;
        requestId = cowId * 100000000 + date; // 66666620180822
    Requests[requestId] = Request(cowId, date, msg.sender);
        Requesthistory.push(requestId);
        TobeCheck.push(requestId);

    return requestId;
  }

   
    function vetCheck(bool check, uint requestId, uint checkdate) public returns (uint) {
      // require(!StringUtils.equal(Requests[requestId],"0"));
      // require(StringUtils.equal(CheckedRequests[requestId], "0"));
      
      CheckedRequests[requestId] = CheckedRequest(Requests[requestId], check, checkdate, msg.sender);
        delete TobeCheck[TobeCheck.length - 1];
        TobeReply.push(requestId);

      return requestId;
    }


    function replayClaim(bool reply, uint requestId, uint replydate) public returns (uint) {
    
      ReplyedRequests[requestId] = ReplyedRequest(CheckedRequests[requestId], reply, replydate, msg.sender);
        delete TobeReply[TobeReply.length - 1];

      return requestId;
    }


    function getRequest(uint index) public view returns (uint[]) {
        if (index == 0){
            return Requesthistory;    
        } else if (index == 1) {
            return TobeCheck;
        } else {
            return TobeReply;
        }
        
    }

    

} 