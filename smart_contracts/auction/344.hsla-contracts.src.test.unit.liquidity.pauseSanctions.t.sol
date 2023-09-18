// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "../../utils/fixtures/OffersLoansRefinancesFixtures.sol";
import "../../../interfaces/niftyapes/offers/IOffersStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../../interfaces/niftyapes/lending/ILendingEvents.sol";

contract TestLiquidityPauseSanctions is Test, OffersLoansRefinancesFixtures {
    function setUp() public override {
        super.setUp();
    }

    function test_unit_liquidity_pauseSanctions_works() public {
        if (integration) {
            vm.startPrank(daiWhale);
            daiToken.transfer(SANCTIONED_ADDRESS, daiToken.balanceOf(daiWhale));
            vm.stopPrank();
        } else {
            daiToken.mint(SANCTIONED_ADDRESS, 3672711471 ether);
        }

        vm.startPrank(owner);
        liquidity.pauseSanctions();
        vm.stopPrank();

        vm.startPrank(SANCTIONED_ADDRESS);
        daiToken.approve(address(liquidity), 1);
        liquidity.supplyErc20(address(daiToken), 1);
        vm.stopPrank();
    }

    function test_unit_liquidity_cannot_pauseSanctions_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        liquidity.pauseSanctions();
    }

    function test_unit_liquidity_unpauseSanctions_works() public {
        if (integration) {
            vm.startPrank(daiWhale);
            daiToken.transfer(SANCTIONED_ADDRESS, daiToken.balanceOf(daiWhale));
            vm.stopPrank();
        } else {
            daiToken.mint(SANCTIONED_ADDRESS, 3672711471 ether);
        }

        vm.startPrank(owner);
        liquidity.pauseSanctions();
        vm.stopPrank();

        vm.startPrank(SANCTIONED_ADDRESS);
        daiToken.approve(address(liquidity), 1);
        liquidity.supplyErc20(address(daiToken), 1);
        vm.stopPrank();
        vm.startPrank(owner);
        liquidity.unpauseSanctions();
        vm.stopPrank();

        vm.startPrank(SANCTIONED_ADDRESS);
        vm.expectRevert("00017");
        liquidity.withdrawErc20(address(daiToken), 1);
    }

    function test_unit_liquidity_cannot_unpauseSanctions_notOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        liquidity.unpauseSanctions();
    }
}
