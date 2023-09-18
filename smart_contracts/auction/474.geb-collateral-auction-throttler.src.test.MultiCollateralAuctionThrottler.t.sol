pragma solidity 0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "geb/multi/MultiSAFEEngine.sol";
import "geb/multi/MultiLiquidationEngine.sol";
import "./mock/MockTreasury.sol";

import {MultiCollateralAuctionThrottler} from "../MultiCollateralAuctionThrottler.sol";

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract CustomMultiSAFEEngine is MultiSAFEEngine {
    function modifyGlobalDebt(bytes32 coinName, bytes32 parameter, uint data) external {
        globalDebt[coinName] = data;
    }
    function modifyUnbackedDebt(bytes32 coinName, bytes32 parameter, uint data) external {
        globalUnbackedDebt[coinName] = data;
    }
}

contract CustomMultiLiquidationEngine is MultiLiquidationEngine {
    constructor(address safeEngine) public MultiLiquidationEngine(safeEngine) {}

    function modifyCurrentOnAuctionSystemCoins(bytes32 coinName, uint256 data) public {
        currentOnAuctionSystemCoins[coinName] = data;
    }
}

contract MultiCollateralAuctionThrottlerTest is DSTest {
    Hevm hevm;

    DSToken systemCoin;

    CustomMultiSAFEEngine safeEngine;
    CustomMultiLiquidationEngine liquidationEngine;
    MultiMockTreasury treasury;

    MultiCollateralAuctionThrottler throttler;

    // Throttler vars
    uint256 updateDelay                     = 1 hours;
    uint256 backupUpdateDelay               = 6 hours;
    uint256 baseUpdateCallerReward          = 5E18;
    uint256 maxUpdateCallerReward           = 10E18;
    uint256 maxRewardIncreaseDelay          = 6 hours;
    uint256 perSecondCallerRewardIncrease   = 1000192559420674483977255848; // 100% per hour
    uint256 globalDebtPercentage            = 20;
    address[] surplusHolders;

    address alice   = address(0x1);
    address bob     = address(0x2);
    address charlie = address(0x3);

    bytes32 coinName = "BAI";

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        surplusHolders.push(alice);
        surplusHolders.push(bob);

        systemCoin        = new DSToken("RAI", "RAI");
        safeEngine        = new CustomMultiSAFEEngine();
        liquidationEngine = new CustomMultiLiquidationEngine(address(safeEngine));
        treasury          = new MultiMockTreasury(address(systemCoin));

        safeEngine.initializeCoin(coinName, uint(-1));
        liquidationEngine.initializeCoin(coinName, uint(-1));

        systemCoin.mint(address(treasury), 1000E18);

        throttler         = new MultiCollateralAuctionThrottler(
          coinName,
          address(safeEngine),
          address(liquidationEngine),
          address(treasury),
          updateDelay,
          backupUpdateDelay,
          baseUpdateCallerReward,
          maxUpdateCallerReward,
          perSecondCallerRewardIncrease,
          globalDebtPercentage,
          surplusHolders
        );
        throttler.modifyParameters("maxRewardIncreaseDelay", 6 hours);

        treasury.setPerBlockAllowance(coinName, address(throttler), maxUpdateCallerReward * 10 ** 27);
        treasury.setTotalAllowance(coinName, address(throttler), uint(-1));

        liquidationEngine.addAuthorization(coinName, address(throttler));

        delete(surplusHolders);
    }

    function test_setup() public {
        assertEq(address(throttler.safeEngine()), address(safeEngine));
        assertEq(address(throttler.liquidationEngine()), address(liquidationEngine));
        assertEq(address(throttler.treasury()), address(treasury));

        assertEq(throttler.coinName(), coinName);
        assertEq(throttler.updateDelay(), updateDelay);
        assertEq(throttler.backupUpdateDelay(), backupUpdateDelay);
        assertEq(throttler.globalDebtPercentage(), globalDebtPercentage);
        assertEq(throttler.surplusHolders(0), alice);
        assertEq(throttler.surplusHolders(1), bob);
        assertEq(throttler.baseUpdateCallerReward(), baseUpdateCallerReward);
        assertEq(throttler.maxUpdateCallerReward(), maxUpdateCallerReward);
        assertEq(throttler.perSecondCallerRewardIncrease(), perSecondCallerRewardIncrease);
    }
    function test_modify_parameters() public {
        liquidationEngine = new CustomMultiLiquidationEngine(address(safeEngine));
        treasury          = new MultiMockTreasury(address(systemCoin));

        liquidationEngine.initializeCoin(coinName, uint(-1));

        throttler.modifyParameters("treasury", address(treasury));
        throttler.modifyParameters("liquidationEngine", address(liquidationEngine));
        throttler.modifyParameters("baseUpdateCallerReward", 1);
        throttler.modifyParameters("perSecondCallerRewardIncrease", 10 ** 27 + 1);
        throttler.modifyParameters("maxUpdateCallerReward", 2);
        throttler.modifyParameters("maxRewardIncreaseDelay", 1 hours);
        throttler.modifyParameters("updateDelay", 30 minutes);
        throttler.modifyParameters("backupUpdateDelay", 50 minutes);
        throttler.modifyParameters("globalDebtPercentage", 90);

        assertEq(address(throttler.liquidationEngine()), address(liquidationEngine));
        assertEq(address(throttler.treasury()), address(treasury));

        assertEq(throttler.updateDelay(), 30 minutes);
        assertEq(throttler.backupUpdateDelay(), 50 minutes);
        assertEq(throttler.globalDebtPercentage(), 90);
        assertEq(throttler.surplusHolders(0), alice);
        assertEq(throttler.surplusHolders(1), bob);
        assertEq(throttler.baseUpdateCallerReward(), 1);
        assertEq(throttler.maxUpdateCallerReward(), 2);
        assertEq(throttler.perSecondCallerRewardIncrease(), 10 ** 27 + 1);
    }
    function test_computed_amount_lower_than_on_auction_system_coins() public {
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 100E45);
        liquidationEngine.modifyCurrentOnAuctionSystemCoins(coinName, 75E45);

        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 75E45);
    }
    function test_auto_recompute_zero_global_debt_zero_min() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), uint(-1));
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
    }
    function test_auto_recompute_zero_global_debt_positive_min() public {
        throttler.modifyParameters("minAuctionLimit", 5E75);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 5E75);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
    }
    function test_auto_recompute_twice_positive_global_debt() public {
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 1E45);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 0.2E45);

        hevm.warp(now + updateDelay);

        assertEq(throttler.treasuryAllowance(), maxUpdateCallerReward * 10 ** 27);
        assertEq(throttler.getCallerReward(throttler.lastUpdateTime(), updateDelay), baseUpdateCallerReward);
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 5E75);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward * 2);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 1E75);
    }
    function testFail_auto_recompute_twice_same_block() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
    }
    function testFail_auto_recompute_before_delay_elapses() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        hevm.warp(now + updateDelay - 1);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
    }
    function test_auto_recompute_both_addresses_have_surplus_positive_unbacked_debt() public {
        safeEngine.createUnbackedDebt(coinName, address(this), address(alice), 1e45);
        safeEngine.createUnbackedDebt(coinName, address(this), address(bob), 1e45);

        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 5E45);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 0.2E45);
    }
    function test_auto_recompute_non_null_unbacked_debt() public {
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 5E45);
        safeEngine.modifyUnbackedDebt(coinName, "globalUnbackedDebt", 2E45);

        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 0.6E45);
    }
    function test_auto_recompute_global_debt_max_uint() public {
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", uint(-1));
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(systemCoin.balanceOf(charlie), baseUpdateCallerReward);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), uint(-1) / 100 * globalDebtPercentage);
    }
    function test_late_auto_recompute() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        hevm.warp(now + backupUpdateDelay);

        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 1E45);
        throttler.backupRecomputeOnAuctionSystemCoinLimit();
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), uint(-1));
    }
    function testFail_late_auto_recompute_twice_same_block() public {
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 1E45);
        throttler.backupRecomputeOnAuctionSystemCoinLimit();
        throttler.backupRecomputeOnAuctionSystemCoinLimit();
    }
    function test_late_auto_recompute_global_debt_max_uint() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        hevm.warp(now + backupUpdateDelay);

        safeEngine.modifyGlobalDebt(coinName, "globalDebt", uint(-1));
        throttler.backupRecomputeOnAuctionSystemCoinLimit();
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), uint(-1));
    }
    function testFail_late_auto_recompute_before_late_delay() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        hevm.warp(now + backupUpdateDelay);

        safeEngine.modifyGlobalDebt(coinName, "globalDebt", uint(-1));
        throttler.backupRecomputeOnAuctionSystemCoinLimit();
        assertEq(throttler.lastUpdateTime(), now);

        hevm.warp(now + backupUpdateDelay - 1);
        throttler.backupRecomputeOnAuctionSystemCoinLimit();
    }
    function test_auto_update_after_backup_update() public {
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        hevm.warp(now + backupUpdateDelay);

        safeEngine.modifyGlobalDebt(coinName, "globalDebt", uint(-1));
        throttler.backupRecomputeOnAuctionSystemCoinLimit();

        hevm.warp(now + updateDelay);
        safeEngine.modifyGlobalDebt(coinName, "globalDebt", 1E45);
        throttler.recomputeOnAuctionSystemCoinLimit(charlie);
        assertEq(liquidationEngine.onAuctionSystemCoinLimit(coinName), 0.2E45);
    }
}
