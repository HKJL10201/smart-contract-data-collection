

//jshint ignore: start

pragma solidity ^0.4.11;

import './Ownable.sol';
import './Donatti.sol';

contract Don is Ownable {
  
  //books
  uint256 public collected;
  uint256 public totalCollected;
  
  //donatti
  address private donatti;
  
  //params
  string private name;
  bool private open; //open or closed
  bool private over; //allow over collecting
  uint256 private start;
  uint256 private end;
  uint256 private goal;
  //optional params
  string private url;
  
  /**************************************
  * Modifiers
  **************************************/
  modifier isOpen() {
    require(open && (over || goal == 0 || collected < goal) && (now > start && now < end));
    _;
  }
  
  /**************************************
  * Payable
  **************************************/
  function() payable isOpen {
    collected += msg.value;
    totalCollected += msg.value;
    //transfer fee to Donatti
    donatti.transfer((msg.value - (msg.value % 100)) / 100);
    //credit the owner with DONTs
    Donatti(donatti).credit(owner, msg.value * 1000);
  }
  
  /**************************************
  * Public Functions
  **************************************/
  function Don(address _donatti) {
    donatti = _donatti;
  }
  
  function getParameters() constant returns (string, bool, bool, uint256, uint256, uint256, string) {
    return (name, open, over, start, end, goal, url);
  }
  
  /**************************************
  * Only Owner Functions
  **************************************/
  function update(string _name, bool _open, bool _over, uint256 _start, uint256 _end, uint256 _goal, string _url) onlyOwner {
    name = _name;
    open = _open;
    over = _over;
    start = _start;
    end = _end;
    goal = _goal;
    url = _url;
  }
  
  function reset() onlyOwner {
    collected = 0;
  }
  
}

//jshint ignore: end