// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "./CompoundDeployment.sol";

contract LenderLiquidityFixtures is Test, CompoundDeployment {
    uint256 internal defaultEthLiquiditySupplied;
    uint256 internal defaultDaiLiquiditySupplied;

    function setUp() public virtual override {
        super.setUp();

        defaultEthLiquiditySupplied = address(lender1).balance;

        if (integration) {
            defaultDaiLiquiditySupplied = daiToken.balanceOf(lender1);
        } else {
            defaultDaiLiquiditySupplied = 3672711471 * uint128(10**daiToken.decimals());
        }

        vm.startPrank(lender1);
        liquidity.supplyEth{ value: defaultEthLiquiditySupplied }();
        daiToken.approve(address(liquidity), daiToken.balanceOf(lender1));
        liquidity.supplyErc20(address(daiToken), daiToken.balanceOf(lender1));
        vm.stopPrank();

        vm.startPrank(lender2);
        liquidity.supplyEth{ value: defaultEthLiquiditySupplied }();
        daiToken.approve(address(liquidity), daiToken.balanceOf(lender2));
        liquidity.supplyErc20(address(daiToken), daiToken.balanceOf(lender2));
        vm.stopPrank();

        vm.startPrank(lender3);
        liquidity.supplyEth{ value: defaultEthLiquiditySupplied }();
        daiToken.approve(address(liquidity), daiToken.balanceOf(lender3));
        liquidity.supplyErc20(address(daiToken), daiToken.balanceOf(lender3));
        vm.stopPrank();
    }

    function resetSuppliedDaiLiquidity(address lender, uint256 amount) internal {
        vm.startPrank(lender);
        liquidity.withdrawErc20(
            address(daiToken),
            liquidity.cAssetAmountToAssetAmount(
                address(cDAIToken),
                liquidity.getCAssetBalance(lender, address(cDAIToken))
            )
        );
        daiToken.approve(address(liquidity), amount);
        liquidity.supplyErc20(address(daiToken), amount);
        vm.stopPrank();
    }

    function resetSuppliedEthLiquidity(address lender, uint256 amount) internal {
        vm.startPrank(lender);
        liquidity.withdrawEth(
            liquidity.cAssetAmountToAssetAmount(
                address(cEtherToken),
                liquidity.getCAssetBalance(lender, address(cEtherToken))
            )
        );
        liquidity.supplyEth{ value: amount }();
        vm.stopPrank();
    }
}
