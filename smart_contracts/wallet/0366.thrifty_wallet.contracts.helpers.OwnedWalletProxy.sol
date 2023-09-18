pragma solidity ^0.4.24;

import "../Thrifty.sol";

// Test against a version of the contract where now is frozen in time
contract MockThrifty is Thrifty {
  uint private fakeNow;
  event LogInt(uint n);

  constructor(uint secondsSinceEpoch) public {
    fakeNow = secondsSinceEpoch;
  }
  
  function getCurrentTimestamp() view internal returns (uint) {     
    return fakeNow;
  }

  function travel(uint newTimestamp) public {
    fakeNow = newTimestamp;
  }
}

contract OwnedWalletProxy {
  MockThrifty public wallet;
  bytes private data;

  constructor() public payable {
    wallet = new MockThrifty(1539471600);
  }

  function() public payable {
    if(msg.data.length > 0) {
      data = msg.data;
    }
  }

  function execute() public payable returns (bool) {
    return address(wallet).call(data);
  }

  function fundWallet(uint amount) public {
    address(wallet).transfer(amount);
  }

  function walletBalance() view public returns (uint) {
    return address(wallet).balance;
  }
}
