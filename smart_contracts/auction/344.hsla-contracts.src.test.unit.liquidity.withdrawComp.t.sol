// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestWithdrawComp is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_withdrawComp_owner_works(uint128 amount) private {
        if (integration) {
            vm.startPrank(compWhale);
            compToken.transfer(address(liquidity), compToken.balanceOf(compWhale));
            vm.stopPrank();
        } else {
            compToken.mint(address(liquidity), 3672711471 ether);
        }
        // avoid `redeemTokens zero` error by providing at least 1 COMP
        vm.assume(amount > 0);
        vm.assume(amount <= compToken.balanceOf(address(liquidity)));

        uint256 compBalanceBefore = compToken.balanceOf(address(liquidity));
        uint256 regenBalanceBefore = compToken.balanceOf(liquidity.regenCollectiveAddress());

        assertEq(regenBalanceBefore, 0);

        vm.startPrank(owner);

        uint256 compWithdrawn = liquidity.withdrawComp();

        vm.stopPrank();

        uint256 compBalanceAfter = compToken.balanceOf(owner);
        uint256 regenBalanceAfter = compToken.balanceOf(liquidity.regenCollectiveAddress());

        uint256 expectedRegenAmount = (amount * liquidity.regenCollectiveBpsOfRevenue()) / 10_000;

        isApproxEqual(amount, compWithdrawn, 1);
        isApproxEqual((expectedRegenAmount), (compBalanceBefore - compBalanceAfter), 1);
        isApproxEqual(expectedRegenAmount, regenBalanceAfter, 1);
    }

    function test_fuzz_withdrawComp_owner_works(uint128 amount) public {
        _test_withdrawComp_owner_works(amount);
    }

    function test_unit_withdrawComp_owner_works() public {
        uint128 amount = 1 ether;

        _test_withdrawComp_owner_works(amount);
    }

    function test_unit_cannot_withdrawComp_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        liquidity.withdrawComp();
    }
}
