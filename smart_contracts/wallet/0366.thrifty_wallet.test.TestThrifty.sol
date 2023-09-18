pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Thrifty.sol";
import "test/helpers/ThrowProxy.sol";
import "test/helpers/GenericTest.sol";
import "../contracts/helpers/OwnedWalletProxy.sol";

contract TestThrifty is GenericTest {
   uint public initialBalance = 10 ether;

   OwnedWalletProxy owner;
   Thrifty instance;

   function beforeAll() public {
     owner = OwnedWalletProxy(DeployedAddresses.OwnedWalletProxy());
     instance = new Thrifty();
   }

   function testEmptyWalletHasZeroBalance() public {
     Assert.equal(address(new Thrifty()).balance, 0, "A new, empty wallet should have zero balance");
   }

   function testEmptyWalletHasZeroDailyLimit() public {
     Assert.equal(instance.dailyLimit(), 0, "A new wallet will not allow withdrawl until the owner sets a daily limit");
   }

   function testOwnerCanSetDailyLimit() public {
     Thrifty(address(owner)).setDailyLimit(100 wei);
     Assert.isTrue(owner.execute(), "should work");
     
     Assert.equal(owner.wallet().dailyLimit(), 100 wei, "The setter should update the daily limit to 10 wei");

     // Try withdrawing from the test contract
     ThrowProxy t = new ThrowProxy(address(owner.wallet()));
     Thrifty(address(t)).setDailyLimit(1000 ether);
     Assert.isFalse(t.execute.gas(200000 wei)(), "Expected an exception because the test contract doesn't own the wallet");

     Assert.equal(owner.wallet().dailyLimit(), 100 wei, "The limit should stil be 10 because only the owner can update");
   }

   function testFundingWallet() public {
     owner.fundWallet(200 wei);
     
     Assert.equal(address(owner.wallet()).balance, 200 wei, "The amount is transferred to the smart contract account");
   }

   function testWithdrawingFundsUnderDailyLimit() public {
     Thrifty(address(owner)).withdraw(10 wei);	     
     assertChangesBy(owner.execute, owner.walletBalance, -10 wei, "Expected withdrawl to decrease wallet balance by 10 wei");      
     Assert.equal(address(owner.wallet()).balance, 190 wei, "The wallet should have 190 wei remaining");
   }

   function testWithdrawlSetLimitStartTime() public {
     Assert.equal(owner.wallet().limitStartTime(), 1539471600, "Expected the limit start time to be set");
   }

   function testWithdrawlCalculatesLimitEndTime() public {
     Assert.equal(owner.wallet().limitEndTime(), 1539558000, "Expected the end time to be a day after the withdrawl");
   }

   function testWithdrawlKnowsTodaysSpend() public {
     Assert.equal(owner.wallet().withdrawnToday(), 10 wei, "The contract remembers that 10 wei was spent today");
   }

   function testRemainingLimit() public {
     Assert.equal(owner.wallet().todaysLimit(), 90 wei, "The contrat knows 190 is remaining");
   }

   function testWithdrawingMoreThanLimitRaisesError() public {
     // Try and withdraw 200 wei
     ThrowProxy t = new ThrowProxy(address(owner.wallet()));
     Thrifty(address(t)).withdraw(200 wei);
     Assert.isFalse(t.execute.gas(200000 wei)(), "Expected an exception because we've exceeded the daily limit");
   }

   function testThirdPartyCantWithdraw() public {
     ThrowProxy t = new ThrowProxy(address(owner.wallet()));
     Thrifty(address(t)).withdraw(100 wei);
     Assert.isFalse(t.execute.gas(200000 wei)(), "Expected an exception because the test contract doesn't own the wallet");
   }

   function testOwnerWithdrawsDailyLimit() public  {
     // Still 190 left today
     Thrifty(address(owner)).withdraw(90 wei);
     Assert.isTrue(owner.execute(), "should work");

     Thrifty(address(owner)).withdraw(100 wei);
     Assert.isFalse(owner.execute(), "should fail because we've exceeded the 100 wei limit");

     // Mock time to tomorrow
     owner.wallet().travel(1539558000);

     Thrifty(address(owner)).withdraw(100 wei);
     Assert.isTrue(owner.execute(), "should work becuase we're on tomorrow's limit");
   }

   // A payable fallback function lets us test transfer calls
   function() external payable {
     
   }
}
