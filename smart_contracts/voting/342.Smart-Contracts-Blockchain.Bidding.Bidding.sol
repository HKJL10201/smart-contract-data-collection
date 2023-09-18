pragma solidity ^0.4.18;
// We have to specify what version of compiler this code will compile with

contract Bidding {
  /* mapping field below is equivalent to an associative array or hash.
  The key of the mapping is candidate name stored as type bytes32 and value is
  an unsigned integer to store the vote count
  */

  mapping (bytes32 => uint32) public bidsReceived;

  /* Solidity doesn't let you pass in an array of strings in the constructor (yet).
  We will use an array of bytes32 instead to store the list of candidates
  */

  // bytes32[] public bidderList;

  /* This is the constructor which will be called once when you
  deploy the contract to the blockchain. When we deploy the contract,
  we will pass an array of candidates who will be contesting in the election
  */
  /*function Bidding(bytes32[] bidderNames) public {
    for(uint8 i =0 ;i<bidderNames.length;i++){
    bidsReceived[bidderNames[i]] = 0;
    }
  }*/

  // This function returns the total votes a candidate has received so far
  function totalBidBy(bytes32 bidder) view public returns (uint32) {
    // require(validBidder(bidder));
    return bidsReceived[bidder];
  }

  // This function increments the vote count for the specified candidate. This
  // is equivalent to casting a vote
  function placeBid(bytes32 bidder,uint32 bid) public {
    // require(validBidder(bidder));
    // require(validVoter(voterHash));
    bidsReceived[bidder] = bid;
    // setVoted(voterHash);
  }

  /*function validBidder(bytes32 bidder) view public returns (bool) {
    for(uint i = 0; i < bidderList.length; i++) {
      if (bidderList[i] == bidder) {
        return true;
      }
    }
    return false;
  }*/
}
