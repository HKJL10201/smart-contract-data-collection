pragma solidity ^0.4.16;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {

 uint public initialBalance = 2 ether;

 function testInitialTokenBalanceUsingDeployedContract() public {
  Voting voting = Voting(DeployedAddresses.Voting());

  uint expected = 10000;

  Assert.equal(voting.balanceTokens(), expected, "10000 Tokens not initialized for sale");
 }

 function testBuyTokens() public {
  Voting voting = Voting(DeployedAddresses.Voting());
  voting.buy.value(1 ether)();
  Assert.equal(voting.balanceTokens(), 9900, "9900 tokens should have been available");
 }

}