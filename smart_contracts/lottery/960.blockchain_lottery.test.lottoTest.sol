pragma solidity ^0.5.3;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Lotto.sol";

contract lottoTest {

  function testInitialBalanceUsingDeployedContract() public {
    Lotto lotto = new Lotto();

    uint expected_amount = 0;
    (bool active, uint bet_amount) = lotto.check();

    Assert.equal(active, false, "Bet should be inactive (false)");
    Assert.equal(bet_amount, expected_amount, "Bet amount should be 0");
  }
}
