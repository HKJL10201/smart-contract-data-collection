pragma solidity 0.6.7;

import "ds-test/test.sol";
import {DSDelegateToken} from "ds-token/delegate.sol";

import {RecyclingSurplusAuctionHouse} from "geb/single/SurplusAuctionHouse.sol";
import "geb/single/SAFEEngine.sol";

import {CoinJoin} from 'geb/shared/BasicTokenAdapters.sol';
import {Coin} from "geb/shared/Coin.sol";

import "./SurplusAuctionTrigger.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract ShutdownableContract {
    uint256 public contractEnabled = 1;

    function shutdown() public {
        contractEnabled = 0;
    }
}

contract AccountingEngine is ShutdownableContract {
    uint256 public surplusAuctionAmountToSell;

    function setAmountToSell(uint256 amount) external {
        surplusAuctionAmountToSell = amount;
    }
}

contract SurplusAuctionTriggerTest is DSTest {
    Hevm hevm;

    RecyclingSurplusAuctionHouse surplusAuctionHouse;
    SAFEEngine safeEngine;
    DSDelegateToken protocolToken;

    AccountingEngine accountingEngine;
    SurplusAuctionTrigger trigger;

    uint256 surplusAuctionAmountToSell = 10E45;
    uint256 debtToMint = 1000E45;
    uint256 debtToTransfer = 200E45;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        safeEngine = new SAFEEngine();
        protocolToken = new DSDelegateToken('', '');

        accountingEngine = new AccountingEngine();
        accountingEngine.setAmountToSell(surplusAuctionAmountToSell);

        surplusAuctionHouse = new RecyclingSurplusAuctionHouse(address(safeEngine), address(protocolToken));
        surplusAuctionHouse.modifyParameters("protocolTokenBidReceiver", address(0x1));

        trigger = new SurplusAuctionTrigger(
          address(safeEngine), address(surplusAuctionHouse), address(accountingEngine)
        );
        surplusAuctionHouse.addAuthorization(address(trigger));

        protocolToken.approve(address(surplusAuctionHouse));

        safeEngine.createUnbackedDebt(address(this), address(this), debtToMint);
    }

    function test_setup() public {
        assertEq(address(trigger.safeEngine()), address(safeEngine));
        assertEq(address(trigger.surplusAuctionHouse()), address(surplusAuctionHouse));
        assertEq(address(trigger.accountingEngine()), address(accountingEngine));
    }
    function testFail_not_enough_to_auction() public {
        trigger.auctionSurplus();
    }
    function testFail_not_enough_surplus() public {
        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell - 1);
        trigger.auctionSurplus();
    }
    function test_auction_once() public {
        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        uint id = trigger.auctionSurplus();
        assertEq(id, 1);
    }
    function test_auction_twice() public {
        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        uint id = trigger.auctionSurplus();
        assertEq(id, 1);

        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        id = trigger.auctionSurplus();
        assertEq(id, 2);
    }
    function testFail_transfer_surplus_nothing_disabled() public {
        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        trigger.transferSurplus(address(0x2), 1);
    }
    function test_transfer_surplus_auction_house_disabled() public {
        surplusAuctionHouse.disableContract();

        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        trigger.transferSurplus(address(0x2), 1);

        assertEq(safeEngine.coinBalance(address(0x2)), 1);
    }
    function test_transfer_surplus_accounting_disabled() public {
        accountingEngine.shutdown();

        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        trigger.transferSurplus(address(0x2), 1);

        assertEq(safeEngine.coinBalance(address(0x2)), 1);
    }
    function test_transfer_surplus_both_disabled() public {
        surplusAuctionHouse.disableContract();
        accountingEngine.shutdown();

        safeEngine.transferInternalCoins(address(this), address(trigger), surplusAuctionAmountToSell);
        trigger.transferSurplus(address(0x2), 1);

        assertEq(safeEngine.coinBalance(address(0x2)), 1);
    }
}
