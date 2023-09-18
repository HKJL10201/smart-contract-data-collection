pragma solidity ^0.4.20;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner  public {
        owner = newOwner;
    }
}

contract EthTrader is usingOraclize, owned{
    using SafeMath for uint;
    using SafeMath for uint256;
 
    modifier onlyWinners {
        require(listOfWinners[msg.sender] == true);
        _;
    }
   
    mapping (address => bool) public hasUserVoted;
    mapping (address => bool) public listOfWinners;
    mapping (uint => Partcipant) player;
    
    
    uint256 public totalGuesses;
    uint256 public winningTime;
    uint256 public balance;
    uint256 public totalWinners;
  
    
      struct Partcipant {
          uint256 timestamp;
          address winnersAddress;
          uint256 guessNumber;
        
    }
     
     
    event EtherReceived(uint amount, uint total);
    event PayoutSent(uint amount, address winner);
    event SomebodyGuessed(address guesser, uint timestamp, uint guesses);
    event OraclizeResult(string message, uint result, uint timestamp);
    event WinnerAnnounced(address winner, uint amount);

   

    function EthTrader() {
        owner = msg.sender;
        totalGuesses = 0;
    }
    
    function() payable public {
        balance = msg.value.add(balance);
        EtherReceived(msg.value, balance);
    }
    
    function makeGuess(uint256 _userGuess) public returns(bool){
        require(hasUserVoted[msg.sender] == false);
        require((1529782083 < _userGuess) && (_userGuess < 1600000000));
            hasUserVoted[msg.sender] = true;
            totalGuesses = totalGuesses.add(1);
            player[totalGuesses].timestamp = _userGuess;
            player[totalGuesses].winnersAddress = msg.sender;
            player[totalGuesses].guessNumber = totalGuesses;
            SomebodyGuessed(msg.sender, _userGuess, totalGuesses);
            return true;
    }

    // Oracalize callback - https://docs.oraclize.it
    function __callback(bytes32 myid, string _result) {
        require(msg.sender == oraclize_cbAddress());
        uint result = stringToUint(_result); //convert Oracalize result to uint
         OraclizeResult("Price checked", result, now);
        if (result >= 100000000){ 
            winningTime = result;
            _winnerCheck();
        }
    }

    function stringToUint(string s) constant returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (b[i] >= 48 && b[i] <= 57) {
                result = result.mul(10).add(uint(b[i]) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
    }

    // Query Kraken API to check ETHUSD price, will trigger __callback method from Oracalize
    function checkPrice() onlyOwner {
        oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
    }
  
  
    function withdraw() public onlyWinners {
        uint256 payout = (balance.div(totalWinners));
        balance = balance.sub(payout);
        msg.sender.transfer(payout);
        PayoutSent(payout, msg.sender);
        
    }
    function _winnerCheck() internal returns (bool) {
        
         for(uint temp = 0; temp < totalGuesses; temp++){
           if(player[temp].timestamp == winningTime.add(86400) || player[temp].timestamp == winningTime.sub(86400)){
               totalWinners.add(1);
               WinnerAnnounced(player[temp].winnersAddress, balance);
               listOfWinners[player[temp].winnersAddress] = true;
               
           }
           
           
            }
            return true;
    }
    
    
    function suicideContract()  onlyOwner public{
        selfdestruct(owner);
    }
    }
    
    



