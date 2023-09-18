// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lottery.sol";

contract TestLottery{

  function testInitialManagerAddress() public{
    Lottery lottery = new Lottery();
    emit ManangerTestData(lottery.manager.address);

    Assert.isNotZero(lottery.manager.address,"Manager is initialized.");
  }

  event ManangerTestData(address expected);
}
