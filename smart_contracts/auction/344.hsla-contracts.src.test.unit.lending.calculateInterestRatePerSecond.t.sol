// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestCalculateInterestRatePerSecond is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_calculateInterestRatePerSecond_math() public {
        uint256 interestBps = 10000;
        uint256 amount = 1 ether;
        uint256 duration = 1 weeks;
        uint256 maxBps = 10000;

        uint256 IRPS = ((amount * interestBps) / duration) / maxBps;

        assertEq(1653439153439, IRPS);
    }

    function test_unit_calculateInterestBps_math() public {
        uint256 interestRatePerSecond = 1653439153439;
        uint256 amount = 1 ether;
        uint256 duration = 1 weeks;
        uint256 maxBps = 10000;

        uint256 interestRateResult = (((interestRatePerSecond * duration) * maxBps) / amount + 1);

        assertEq(10000, interestRateResult);
    }

    function test_fuzz_calculateInterestRatePerSecond_math(
        uint256 interestBps,
        uint256 amount,
        uint256 duration
    ) public {
        uint256 maxBps = 10000;

        vm.assume(interestBps > 0);
        vm.assume(interestBps <= 1000000);
        vm.assume(amount > 0);
        vm.assume(amount <= defaultEthLiquiditySupplied);
        vm.assume(duration >= 1 days);
        vm.assume(duration <= ~uint32(0));

        uint256 IRPS = ((amount * interestBps) / maxBps) / duration;

        if (IRPS == 0 && interestBps != 0) {
            IRPS = 1;
        }

        uint96 calcResult = lending.calculateInterestPerSecond(amount, interestBps, duration);

        assertEq(calcResult, IRPS);
    }
}
