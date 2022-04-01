pragma solidity ^0.4.15;

import '../../contracts/test/XREDTokenSaleTokenMock.sol';

contract ProfitSharingMock is XREDTokenSaleTokenMock {

  function ProfitSharingMock(address initialAccount, uint initialBalance)
    XREDTokenSaleTokenMock(initialAccount, initialBalance) {}

  event MockNow(uint _now);

  uint mock_now = 1;

  function getNow() internal constant returns (uint) {
      return mock_now;
  }

  function setMockedNow(uint _b) public {
      mock_now = _b;
      MockNow(_b);
  }

}
