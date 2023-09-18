// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestWithdrawCErc20 is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_withdrawCErc20_works(uint128 amount) private {
        if (integration) {
            vm.startPrank(daiWhale);
            daiToken.transfer(borrower1, daiToken.balanceOf(daiWhale));
            vm.stopPrank();
        } else {
            daiToken.mint(borrower1, 3672711471 ether);
        }

        vm.startPrank(borrower1);

        daiToken.approve(address(cDAIToken), daiToken.balanceOf(borrower1));

        cDAIToken.mint(daiToken.balanceOf(borrower1));

        // avoid `redeemTokens zero` error by providing at least 1 cDAI
        vm.assume(amount >= 100000000);
        vm.assume(amount < cDAIToken.balanceOf(borrower1));

        uint256 balanceBefore = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(balanceBefore, 0);

        cDAIToken.approve(address(liquidity), amount);
        uint256 cTokensTransferred = liquidity.supplyCErc20(address(cDAIToken), amount);

        uint256 balanceAfterSupply = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(balanceAfterSupply, cTokensTransferred);

        uint256 cTokensWithdrawn = liquidity.withdrawCErc20(address(cDAIToken), amount);
        uint256 balanceAfterWithdraw = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(cTokensWithdrawn, balanceAfterSupply);
        assertEq(balanceAfterWithdraw, 0);

        vm.stopPrank();
    }

    function test_fuzz_withdrawCErc20_works(uint128 amount) public {
        _test_withdrawCErc20_works(amount);
    }

    function test_unit_withdrawCErc20_works() public {
        uint128 amount = 100000000;

        _test_withdrawCErc20_works(amount);
    }

    function _test_withdrawCErc20_owner_works(uint128 amount) private {
        if (integration) {
            vm.startPrank(daiWhale);
            daiToken.transfer(owner, daiToken.balanceOf(daiWhale));
            vm.stopPrank();
        } else {
            daiToken.mint(owner, 3672711471 ether);
        }

        vm.startPrank(owner);

        daiToken.approve(address(cDAIToken), daiToken.balanceOf(owner));

        cDAIToken.mint(daiToken.balanceOf(owner) / 10000);

        // avoid `redeemTokens zero` error by providing at least 1 cDAI
        vm.assume(amount >= 100000000);
        vm.assume(amount < cDAIToken.balanceOf(owner) / 10000);

        uint256 cDAIBalanceBefore = cDAIToken.balanceOf(owner);

        uint256 regenBalanceBefore = cDAIToken.balanceOf(liquidity.regenCollectiveAddress());
        uint256 balanceBefore = liquidity.getCAssetBalance(owner, address(cDAIToken));

        assertEq(balanceBefore, 0);
        assertEq(regenBalanceBefore, 0);

        cDAIToken.approve(address(liquidity), amount);
        uint256 cTokensTransferred = liquidity.supplyCErc20(address(cDAIToken), amount);

        uint256 balanceAfterSupply = liquidity.getCAssetBalance(owner, address(cDAIToken));

        assertEq(balanceAfterSupply, cTokensTransferred);

        uint256 cTokensWithdrawn = liquidity.withdrawCErc20(address(cDAIToken), amount);
        uint256 balanceAfterWithdraw = liquidity.getCAssetBalance(owner, address(cDAIToken));

        uint256 cDAIBalanceAfter = cDAIToken.balanceOf(owner);
        uint256 regenBalanceAfter = cDAIToken.balanceOf(liquidity.regenCollectiveAddress());

        uint256 expectedRegenAmount = (amount * liquidity.regenCollectiveBpsOfRevenue()) / 10_000;

        isApproxEqual(cTokensWithdrawn, balanceAfterSupply, 1);
        isApproxEqual(balanceAfterWithdraw, 0, 1);
        isApproxEqual(amount, cTokensWithdrawn, 1);
        isApproxEqual((expectedRegenAmount), (cDAIBalanceBefore - cDAIBalanceAfter), 1);
        isApproxEqual(expectedRegenAmount, regenBalanceAfter, 1);

        vm.stopPrank();
    }

    function test_fuzz_withdrawCErc20_owner_works(uint128 amount) public {
        _test_withdrawCErc20_owner_works(amount);
    }

    function test_unit_withdrawCErc20_owner_works() public {
        uint128 amount = 100000000;

        _test_withdrawCErc20_owner_works(amount);
    }
}
