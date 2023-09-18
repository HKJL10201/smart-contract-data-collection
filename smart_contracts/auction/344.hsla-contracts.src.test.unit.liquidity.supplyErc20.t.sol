// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestSupplyErc20 is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_supplyErc20_works(uint128 amount) private {
        if (integration) {
            vm.startPrank(daiWhale);
            daiToken.transfer(borrower1, daiToken.balanceOf(daiWhale));
            vm.stopPrank();
        } else {
            daiToken.mint(borrower1, 3672711471 ether);
        }

        vm.assume(amount > 0);
        vm.assume(amount <= daiToken.balanceOf(borrower1));

        uint256 balanceBefore = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(balanceBefore, 0);

        vm.startPrank(borrower1);
        daiToken.approve(address(liquidity), amount);
        uint256 cTokensMinted = liquidity.supplyErc20(address(daiToken), amount);
        vm.stopPrank();

        uint256 balanceAfter = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(balanceAfter, cTokensMinted);
    }

    function test_fuzz_supplyErc20_works(uint128 amount) public {
        _test_supplyErc20_works(amount);
    }

    function test_unit_supplyErc20_works() public {
        uint128 amount = 1 ether;

        _test_supplyErc20_works(amount);
    }
}
