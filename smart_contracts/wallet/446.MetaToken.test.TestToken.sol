pragma solidity ^0.6.1;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MetaCoin.sol";

contract TestWallet {
    uint public initialBalance = 10 ether;
    MetaCoin public metaCoin;
    address walletOwner = address(this);

    function beforeEach() public {
        metaCoin = MetaCoin(DeployedAddresses.MetaCoin());
    }

    function testDepositWithLessThanMinimumTokens() public {
        metaCoin.depositMoney{value : 100 wei}();
        // uint balance = metaCoin.getBalance();
        // bool status = DeployedAddresses.MetaCoin().send(1);
        // metaCoin.depositMoney{value: 1 wei}();

        // Assert.isFalse(100 == balance, "Should be false because minimum deposit is 0.1 ETH");
    }

    // function testDepositWithNotEnoughFunds() public {

    // }

    // function testDepositSuccessfully() public {

    // }

    // function testCounter() public {

    // }

    // function testBalance() public {

    // }

    // function testWithdrawWithUnsatisfiedCounter() public {

    // }

    // function testWithdrawSuccessfully() public {

    // }
}
