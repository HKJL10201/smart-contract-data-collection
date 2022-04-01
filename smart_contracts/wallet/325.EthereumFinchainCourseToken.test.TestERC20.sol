pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EthereumFinchainCourse.sol";

contract TestERC20 {

  function testInitialBalanceUsingDeployedContract() public {
    EthereumFinchainCourse token = EthereumFinchainCourse(DeployedAddresses.EthereumFinchainCourse());

    uint expected = 1000000000000;

    Assert.equal(token.balanceOf(msg.sender), expected, "Owner has 1000000000000 ETHFC");
  }

  function testTotalSupply() public {
    EthereumFinchainCourse token = new EthereumFinchainCourse("Ethereum Finchain Course", "ETHFC", 8, 10000);

    uint expected = 1000000000000;

    Assert.equal(token.totalSupply(), expected, "Total supply should is 1000000000000 ETHFC");
  }

  function testTransfer() public {
    EthereumFinchainCourse token = new EthereumFinchainCourse("Ethereum Finchain Course", "ETHFC", 8, 10000);
    address to = 0xf17f52151EbEF6C7334FAD080c5704D77216b732;
    uint256 value = 50;

    token.transfer(to, value);

    Assert.equal(token.balanceOf(to), value, "Owner has 1000000000000 ETHFC");
  }
}
