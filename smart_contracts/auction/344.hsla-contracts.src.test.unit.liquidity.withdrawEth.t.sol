// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestWithdrawEth is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_withdrawEth_works(uint128 amount) private {
        vm.assume(amount > 0.5 ether);
        vm.assume(amount <= address(borrower1).balance);

        uint256 balanceBefore = liquidity.getCAssetBalance(borrower1, address(cEtherToken));

        assertEq(balanceBefore, 0);

        vm.startPrank(borrower1);
        uint256 cTokensMinted = liquidity.supplyEth{ value: amount }();

        uint256 balanceAfterSupply = liquidity.getCAssetBalance(borrower1, address(cEtherToken));

        assertEq(balanceAfterSupply, cTokensMinted);

        uint256 cTokensWithdrawn = liquidity.withdrawEth(amount);
        uint256 balanceAfterWithdraw = liquidity.getCAssetBalance(borrower1, address(cEtherToken));

        uint256 underlyingWithdrawn = liquidity.cAssetAmountToAssetAmount(
            address(cEtherToken),
            cTokensWithdrawn
        );

        assertEq(cTokensWithdrawn, balanceAfterSupply);
        assertEq(balanceAfterWithdraw, 0);
        isApproxEqual(amount, underlyingWithdrawn, 1);

        vm.stopPrank();
    }

    function test_fuzz_withdrawEth_works(uint128 amount) public {
        _test_withdrawEth_works(amount);
    }

    function test_unit_withdrawEth_works() public {
        uint128 amount = 1 ether;

        _test_withdrawEth_works(amount);
    }

    function _test_withdrawEth_owner_works(uint128 amount) private {
        vm.deal(owner, defaultInitialEthBalance);

        vm.assume(amount > 0.5 ether);
        vm.assume(amount <= address(owner).balance);

        uint256 ethBalanceBefore = address(owner).balance;

        uint256 balanceBefore = liquidity.getCAssetBalance(owner, address(cEtherToken));

        assertEq(balanceBefore, 0);

        vm.startPrank(owner);
        uint256 cTokensMinted = liquidity.supplyEth{ value: amount }();

        uint256 balanceAfterSupply = liquidity.getCAssetBalance(owner, address(cEtherToken));

        assertEq(balanceAfterSupply, cTokensMinted);

        uint256 cTokensWithdrawn = liquidity.withdrawEth(amount);
        uint256 balanceAfterWithdraw = liquidity.getCAssetBalance(owner, address(cEtherToken));

        uint256 underlyingWithdrawn = liquidity.cAssetAmountToAssetAmount(
            address(cEtherToken),
            cTokensWithdrawn
        );

        uint256 ethBalanceAfter = address(owner).balance;
        uint256 regenBalanceAfter = address(liquidity.regenCollectiveAddress()).balance;

        uint256 expectedRegenAmount = (amount * liquidity.regenCollectiveBpsOfRevenue()) / 10_000;

        isApproxEqual(cTokensWithdrawn, balanceAfterSupply, 1);
        isApproxEqual(balanceAfterWithdraw, 0, 1);
        isApproxEqual(amount, underlyingWithdrawn, 1);
        isApproxEqual((expectedRegenAmount), (ethBalanceBefore - ethBalanceAfter), 1);
        isApproxEqual(expectedRegenAmount, regenBalanceAfter, 1);

        vm.stopPrank();
    }

    function test_fuzz_withdrawEth_owner_works(uint128 amount) public {
        _test_withdrawEth_owner_works(amount);
    }

    function test_unit_withdrawEth_owner_works() public {
        uint128 amount = 1 ether;

        _test_withdrawEth_owner_works(amount);
    }
}
