// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestSupplyEth is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_supplyEth_works(uint128 amount) private {
        vm.assume(amount > 0);
        vm.assume(amount <= address(borrower1).balance);

        uint256 balanceBefore = liquidity.getCAssetBalance(borrower1, address(cEtherToken));

        assertEq(balanceBefore, 0);

        vm.startPrank(borrower1);
        daiToken.approve(address(liquidity), amount);
        uint256 cTokensMinted = liquidity.supplyEth{ value: amount }();
        vm.stopPrank();

        uint256 balanceAfter = liquidity.getCAssetBalance(borrower1, address(cEtherToken));

        assertEq(balanceAfter, cTokensMinted);
    }

    function test_fuzz_supplyEth_works(uint128 amount) public {
        _test_supplyEth_works(amount);
    }

    function test_unit_supplyEth_works() public {
        uint128 amount = 1 ether;

        _test_supplyEth_works(amount);
    }
}
