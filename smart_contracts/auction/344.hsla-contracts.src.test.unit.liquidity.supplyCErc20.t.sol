// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestSupplyCErc20 is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function _test_supplyCErc20_works(uint128 amount) private {
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

        vm.assume(amount > 0);
        vm.assume(amount < cDAIToken.balanceOf(borrower1));

        uint256 balanceBefore = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(balanceBefore, 0);

        cDAIToken.approve(address(liquidity), amount);
        uint256 cTokensTransferred = liquidity.supplyCErc20(address(cDAIToken), amount);
        vm.stopPrank();

        uint256 balanceAfter = liquidity.getCAssetBalance(borrower1, address(cDAIToken));

        assertEq(balanceAfter, cTokensTransferred);
    }

    function test_fuzz_supplyCErc20_works(uint128 amount) public {
        _test_supplyCErc20_works(amount);
    }

    function test_unit_supplyCErc20_works() public {
        uint128 amount = 100000000;

        _test_supplyCErc20_works(amount);
    }
}
