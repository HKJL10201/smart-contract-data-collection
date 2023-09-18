pragma solidity 0.6.0;

contract tweetAccount{
    
    struct tweet{
        uint timestamp;
        string tweetstring;
    }
    
    /* mapping of person id to all its tweet*/
    
    mapping(uint => tweet) _tweets;
    
    // total no of tweet in above _tweets
    
    uint _numberoftweets;
    
    // "owner of this account : only admin is allowed to tweets
    address  _adminaddress;
    
    constructor() public {
        _numberoftweets  = 0;
        _adminaddress = msg.sender;
    }
    
    // this function return true if sende is admin
    function isAdmin() public view returns(bool){
        
        if(msg.sender == _adminaddress){
            return true;
        
        }
        
    }
    
    // create New tweets
     function do_tweet(string memory tweetstring) public returns(uint){
           if(!isAdmin() ){
                  return 1;
           }
           else if(bytes(tweetstring).length >160){
               return 2;
           }
           else{
               _tweets[_numberoftweets].timestamp = now;
               _tweets[_numberoftweets].tweetstring = tweetstring;
               _numberoftweets++;
               
               return 0;
               
           }
     }
           function get_tweet(uint tweetid) public view returns(string memory tweetstring, uint timestamp){
               tweetstring = _tweets[tweetid].tweetstring;
               timestamp = _tweets[tweetid].timestamp;
           }
           function get_latest_tweet() public view returns(string memory tweetstring, uint timestamp, uint numberoftweets){
               tweetstring = _tweets[_numberoftweets-1].tweetstring;
               timestamp = _tweets[_numberoftweets-1].timestamp;
               numberoftweets = _numberoftweets;
           }
           
       function get_owner_address() public view returns(address){
            
             return _adminaddress;
           
       }
       
       function delete_Account() public {
           if(isAdmin()){
               selfdestruct(msg.sender);
           }
       }

}