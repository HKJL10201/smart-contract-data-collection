pragma solidity ^0.4.24;

contract Thrifty {
  address private owner;
  uint public dailyLimit;
  uint public limitStartTime;
  uint public withdrawnToday;

  constructor() public {
    owner = msg.sender;
  }

  function setDailyLimit(uint newLimit) public onlyOwner {
    dailyLimit = newLimit;
  }

  function withdraw(uint amount) public onlyOwner {
    require(amount <= todaysLimit());

    if(withdrawlMadeOnSameDay()) {
      withdrawnToday += amount;
    } else {
      // Start a new 24 hour period from now
      limitStartTime = getCurrentTimestamp();
      withdrawnToday = amount;
    }
    
    owner.transfer(amount);
  }

  function todaysLimit() view public returns (uint) {
    if(withdrawlMadeOnSameDay()) {
      return dailyLimit - withdrawnToday;
    } else {
      return dailyLimit;
    }
  }

  function day() pure internal returns (uint) {
    return 60 * 60 * 24;
  }

  function withdrawlMadeOnSameDay() view public returns (bool) {
    uint timeNow = getCurrentTimestamp();
    return limitStartTime <= timeNow && limitEndTime() > timeNow;
  }

  function limitEndTime() view public returns (uint) {
    return limitStartTime + day();
  }

  function getCurrentTimestamp() view internal returns (uint) {
    return now;
  }

  function() external payable {}

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}
