// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20Upgradeable.sol";
import "../../interfaces/compound/ICERC20.sol";
import "../../interfaces/compound/ICEther.sol";
import "../../Lending.sol";
import "../../Liquidity.sol";
import "../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";

import "../common/BaseTest.sol";
import "../mock/CERC20Mock.sol";
import "../mock/CEtherMock.sol";
import "../mock/ERC20Mock.sol";

contract LiquidityProvidersUnitTest is BaseTest, ILiquidityEvents {
    NiftyApesLiquidity liquidityProviders;
    ERC20Mock daiToken;
    CERC20Mock cDAIToken;
    CEtherMock cEtherToken;
    address compContractAddress = 0xbbEB7c67fa3cfb40069D19E598713239497A3CA5;

    bool acceptEth;

    address constant NOT_ADMIN = address(0x5050);
    address constant SANCTIONED_ADDRESS = address(0x7FF9cFad3877F21d41Da833E2F775dB0569eE3D9);

    receive() external payable {
        require(acceptEth, "acceptEth");
    }

    function setUp() public {
        liquidityProviders = new NiftyApesLiquidity();
        liquidityProviders.initialize(compContractAddress);

        daiToken = new ERC20Mock();
        daiToken.initialize("USD Coin", "DAI");
        cDAIToken = new CERC20Mock();
        cDAIToken.initialize(daiToken);
        liquidityProviders.setCAssetAddress(address(daiToken), address(cDAIToken));
        liquidityProviders.setMaxCAssetBalance(address(cDAIToken), 2**256 - 1);

        if (block.number == 1) {
            hevm.startPrank(liquidityProviders.owner());
            liquidityProviders.pauseSanctions();
            hevm.stopPrank();
        }

        cEtherToken = new CEtherMock();
        cEtherToken.initialize();

        acceptEth = true;
    }

    function testCannotSupplyErc20_asset_not_whitelisted() public {
        hevm.expectRevert("00040");
        liquidityProviders.supplyErc20(address(0x0000000000000000000000000000000000000001), 1);
    }

    function testSupplyErc20_supply_erc20() public {
        assertEq(daiToken.balanceOf(address(this)), 0);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        daiToken.mint(address(this), 1);
        daiToken.approve(address(liquidityProviders), 1);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        uint256 cTokensMinted = liquidityProviders.supplyErc20(address(daiToken), 1);
        assertEq(cTokensMinted, 1 ether);

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 1 ether);
        assertEq(daiToken.balanceOf(address(this)), 0);
        assertEq(cDAIToken.balanceOf(address(this)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 1 ether);
    }

    function testCannotSupplyErc20_amount_must_be_greater_than_0() public {
        daiToken.mint(address(this), 2);
        daiToken.approve(address(liquidityProviders), 2);

        hevm.expectRevert("00045");

        liquidityProviders.supplyErc20(address(daiToken), 0);
    }

    function testCannotSupplyErc20_maxCAsset_hit() public {
        daiToken.mint(address(this), 2);
        daiToken.approve(address(liquidityProviders), 2);

        liquidityProviders.setMaxCAssetBalance(address(cDAIToken), 1 ether);

        liquidityProviders.supplyErc20(address(daiToken), 1);

        hevm.expectRevert("00044");

        liquidityProviders.supplyErc20(address(daiToken), 1);
    }

    function testSupplyErc20_supply_erc20_with_event() public {
        daiToken.mint(address(this), 1);
        daiToken.approve(address(liquidityProviders), 1);

        hevm.expectEmit(true, false, false, true);

        emit Erc20Supplied(address(this), address(daiToken), 1, 1 ether);

        liquidityProviders.supplyErc20(address(daiToken), 1);
    }

    function testSupplyErc20_supply_erc20_different_exchange_rate() public {
        daiToken.mint(address(this), 1);
        daiToken.approve(address(liquidityProviders), 1);

        cDAIToken.setExchangeRateCurrent(2);

        uint256 cTokensMinted = liquidityProviders.supplyErc20(address(daiToken), 1);
        assertEq(cTokensMinted, 0.5 ether);

        assertEq(
            liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)),
            0.5 ether
        );

        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0.5 ether);
    }

    function testCannotSupplyErc20_mint_fails() public {
        daiToken.mint(address(this), 1);
        daiToken.approve(address(liquidityProviders), 1);

        cDAIToken.setMintFail(true);

        hevm.expectRevert("00037");

        liquidityProviders.supplyErc20(address(daiToken), 1);
    }

    function testCannotSupplyErc20_if_sanctioned() public {
        daiToken.mint(address(this), 1);
        daiToken.approve(address(liquidityProviders), 1);

        hevm.expectRevert("00017");

        hevm.startPrank(SANCTIONED_ADDRESS);

        liquidityProviders.supplyErc20(address(daiToken), 1);
    }

    function testCannotSupplyCErc20_asset_not_whitelisted() public {
        hevm.expectRevert("00041");
        liquidityProviders.supplyCErc20(address(0x0000000000000000000000000000000000000001), 1);
    }

    function testSupplyCErc20_supply_cerc20() public {
        daiToken.mint(address(this), 1);

        cDAIToken.mint(1);
        cDAIToken.approve(address(liquidityProviders), 1);

        liquidityProviders.supplyCErc20(address(cDAIToken), 1);

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 1);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 1);
    }

    function testSupplyCErc20_supply_cerc20_with_event() public {
        daiToken.mint(address(this), 1);

        cDAIToken.mint(1);
        cDAIToken.approve(address(liquidityProviders), 1);

        hevm.expectEmit(true, false, false, true);

        emit CErc20Supplied(address(this), address(cDAIToken), 1);

        liquidityProviders.supplyCErc20(address(cDAIToken), 1);
    }

    function testCannotSupplyCErc20_amount_must_be_greater_than_0() public {
        daiToken.mint(address(this), 2);

        cDAIToken.mint(2);
        cDAIToken.approve(address(liquidityProviders), 2 ether);

        hevm.expectRevert("00045");

        liquidityProviders.supplyCErc20(address(cDAIToken), 0 ether);
    }

    function testCannotSupplyCErc20_maxCAsset_hit() public {
        daiToken.mint(address(this), 2);

        cDAIToken.mint(2);
        cDAIToken.approve(address(liquidityProviders), 2 ether);

        liquidityProviders.setMaxCAssetBalance(address(cDAIToken), 1 ether);

        liquidityProviders.supplyCErc20(address(cDAIToken), 1 ether);

        hevm.expectRevert("00044");

        liquidityProviders.supplyCErc20(address(cDAIToken), 1 ether);
    }

    function testCannotSupplyCErc20_transfer_from_fails() public {
        daiToken.mint(address(this), 1);

        cDAIToken.mint(1);
        cDAIToken.approve(address(liquidityProviders), 1);

        cDAIToken.setTransferFromFail(true);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        liquidityProviders.supplyCErc20(address(cDAIToken), 1);
    }

    function testCannotSupplyCErc20_if_sanctioned() public {
        daiToken.mint(address(this), 1);

        cDAIToken.mint(1);
        cDAIToken.approve(address(liquidityProviders), 1);

        hevm.expectRevert("00017");

        hevm.startPrank(SANCTIONED_ADDRESS);

        liquidityProviders.supplyCErc20(address(cDAIToken), 1);
    }

    function testCannotWithdrawErc20_asset_not_whitelisted() public {
        hevm.expectRevert("00040");
        liquidityProviders.withdrawErc20(address(0x0000000000000000000000000000000000000001), 1);
    }

    function testWithdrawErc20_works() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        uint256 cTokensBurnt = liquidityProviders.withdrawErc20(address(daiToken), 1);
        assertEq(cTokensBurnt, 1 ether);

        assertEq(liquidityProviders.getCAssetBalance(NOT_ADMIN, address(cDAIToken)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(daiToken.balanceOf(NOT_ADMIN), 1);
    }

    function testWithdrawErc20_works_owner() public {
        daiToken.mint(address(this), 100);
        daiToken.approve(address(liquidityProviders), 100);
        liquidityProviders.supplyErc20(address(daiToken), 100);

        uint256 cTokensBurnt = liquidityProviders.withdrawErc20(address(daiToken), 99);
        assertEq(cTokensBurnt, 100 ether);

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(daiToken.balanceOf(address(this)), 99);
        assertEq(daiToken.balanceOf(address(0x252de94Ae0F07fb19112297F299f8c9Cc10E28a6)), 1);
    }

    function testWithdrawErc20_works_event() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        hevm.expectEmit(true, false, false, true);

        emit Erc20Withdrawn(NOT_ADMIN, address(daiToken), 1, 1 ether);

        liquidityProviders.withdrawErc20(address(daiToken), 1);
    }

    function testCannotWithdrawErc20_redeemUnderlyingFails() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        cDAIToken.setRedeemUnderlyingFail(true);

        hevm.expectRevert("00038");

        liquidityProviders.withdrawErc20(address(daiToken), 1);
    }

    function testCannotWithdrawErc20_withdraw_more_than_account_has() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);
        hevm.stopPrank();

        // deposit some funds from a different address
        hevm.startPrank(
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000001)
        );

        daiToken.mint(address(0x0000000000000000000000000000000000000001), 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        hevm.stopPrank();

        hevm.startPrank(NOT_ADMIN);
        hevm.expectRevert("00034");

        liquidityProviders.withdrawErc20(address(daiToken), 2);
        hevm.stopPrank();
    }

    function testCannotWithdrawErc20_underlying_transfer_fails() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        daiToken.setTransferFail(true);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        liquidityProviders.withdrawErc20(address(daiToken), 1);
    }

    function testCannotWithdrawErc20_if_sanctioned() public {
        daiToken.mint(SANCTIONED_ADDRESS, 1);

        hevm.prank(SANCTIONED_ADDRESS);
        daiToken.approve(address(liquidityProviders), 1);

        liquidityProviders.pauseSanctions();

        hevm.prank(SANCTIONED_ADDRESS);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        liquidityProviders.unpauseSanctions();

        hevm.expectRevert("00017");
        hevm.prank(SANCTIONED_ADDRESS);
        liquidityProviders.withdrawErc20(address(daiToken), 1 ether);
    }

    function testWithdrawErc20_regen_collective_event_emits_when_owner() public {
        hevm.startPrank(liquidityProviders.owner());
        daiToken.mint(liquidityProviders.owner(), 100);
        daiToken.approve(address(liquidityProviders), 100);
        liquidityProviders.supplyErc20(address(daiToken), 100);
        hevm.stopPrank();

        hevm.warp(block.timestamp + 1 weeks);

        hevm.expectEmit(true, true, false, false);

        emit PercentForRegen(
            liquidityProviders.regenCollectiveAddress(),
            address(daiToken),
            1,
            100000000000000000
        );

        hevm.startPrank(liquidityProviders.owner());

        liquidityProviders.withdrawErc20(address(daiToken), 100);
    }

    function testCannotWithdrawCErc20_no_asset_balance() public {
        hevm.expectRevert("00045");
        liquidityProviders.withdrawCErc20(address(0x0000000000000000000000000000000000000001), 1);
    }

    function testWithdrawCErc20_works_owner() public {
        daiToken.mint(address(this), 100);
        daiToken.approve(address(liquidityProviders), 100);
        liquidityProviders.supplyErc20(address(daiToken), 100);

        uint256 cTokensBurnt = liquidityProviders.withdrawCErc20(address(cDAIToken), 99);
        assertEq(cTokensBurnt, 100 ether);

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cDAIToken)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(cDAIToken.balanceOf(address(this)), 99 ether);
        assertEq(
            cDAIToken.balanceOf(address(0x252de94Ae0F07fb19112297F299f8c9Cc10E28a6)),
            1 ether
        );
    }

    function testWithdrawCErc20_works() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        liquidityProviders.withdrawCErc20(address(cDAIToken), 1 ether);

        assertEq(liquidityProviders.getCAssetBalance(NOT_ADMIN, address(cDAIToken)), 0);

        assertEq(daiToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(cDAIToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(cDAIToken.balanceOf(NOT_ADMIN), 1 ether);
    }

    function testWithdrawCErc20_works_event() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        hevm.expectEmit(true, false, false, true);

        emit CErc20Withdrawn(NOT_ADMIN, address(cDAIToken), 1 ether);

        liquidityProviders.withdrawCErc20(address(cDAIToken), 1 ether);
    }

    function testCannotWithdrawCErc20_withdraw_more_than_account_has() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);
        hevm.stopPrank();

        // deposit some funds from a different address
        hevm.startPrank(
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000001)
        );

        daiToken.mint(address(0x0000000000000000000000000000000000000001), 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        hevm.expectRevert("00034");

        liquidityProviders.withdrawCErc20(address(cDAIToken), 2 ether);
    }

    function testCannotWithdrawCErc20_transfer_fails() public {
        hevm.startPrank(NOT_ADMIN);
        daiToken.mint(NOT_ADMIN, 1);
        daiToken.approve(address(liquidityProviders), 1);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        cDAIToken.setTransferFail(true);

        hevm.expectRevert("SafeERC20: ERC20 operation did not succeed");

        liquidityProviders.withdrawCErc20(address(cDAIToken), 1 ether);
    }

    function testCannotWithdrawCErc20_if_sanctioned() public {
        daiToken.mint(SANCTIONED_ADDRESS, 1);

        hevm.prank(SANCTIONED_ADDRESS);
        daiToken.approve(address(liquidityProviders), 1);

        liquidityProviders.pauseSanctions();

        hevm.prank(SANCTIONED_ADDRESS);
        liquidityProviders.supplyErc20(address(daiToken), 1);

        liquidityProviders.unpauseSanctions();

        hevm.expectRevert("00017");
        hevm.prank(SANCTIONED_ADDRESS);
        liquidityProviders.withdrawCErc20(address(cDAIToken), 1 ether);
    }

    function testWithdrawCErc20_regen_collective_event_emits_when_owner() public {
        hevm.startPrank(liquidityProviders.owner());
        daiToken.mint(liquidityProviders.owner(), 100);
        daiToken.approve(address(liquidityProviders), 100);
        liquidityProviders.supplyErc20(address(daiToken), 100);
        hevm.stopPrank();

        hevm.warp(block.timestamp + 1 weeks);

        hevm.expectEmit(true, true, false, false);

        emit PercentForRegen(
            liquidityProviders.regenCollectiveAddress(),
            address(cDAIToken),
            1,
            100000000000000000
        );

        hevm.startPrank(liquidityProviders.owner());

        liquidityProviders.withdrawCErc20(address(cDAIToken), 100);
    }

    function testCannotSupplyEth_asset_not_whitelisted() public {
        hevm.expectRevert("00040");
        liquidityProviders.supplyEth{ value: 1 }();
    }

    function testSupplyEth_supply_eth() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.deal(address(liquidityProviders), 0);

        uint256 startingBalance = address(this).balance;
        assertEq(cEtherToken.balanceOf(address(this)), 0);

        assertEq(cEtherToken.balanceOf(address(liquidityProviders)), 0);
        assertEq(address(liquidityProviders).balance, 0);

        uint256 cTokensMinted = liquidityProviders.supplyEth{ value: 1 }();
        assertEq(cTokensMinted, 1 ether);

        assertEq(liquidityProviders.getCAssetBalance(address(this), address(cEtherToken)), 1 ether);
        assertEq(address(this).balance, startingBalance - 1);
        assertEq(cEtherToken.balanceOf(address(this)), 0);

        assertEq(address(cEtherToken).balance, 1);
        assertEq(cEtherToken.balanceOf(address(liquidityProviders)), 1 ether);
    }

    function testSupplyEth_with_event() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.expectEmit(true, false, false, true);

        emit EthSupplied(address(this), 1, 1 ether);

        liquidityProviders.supplyEth{ value: 1 }();
    }

    function testCannotSupplyEth_amount_must_be_greater_than_0() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );

        hevm.expectRevert("00045");

        liquidityProviders.supplyEth{ value: 0 }();
    }

    function testCannotSupplyEth_maxCAsset_hit() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );

        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 1 ether);

        liquidityProviders.supplyEth{ value: 1 }();

        hevm.expectRevert("00044");

        liquidityProviders.supplyEth{ value: 1 }();
    }

    function testSupplyEth_different_exchange_rate() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        cEtherToken.setExchangeRateCurrent(2);

        uint256 cTokensMinted = liquidityProviders.supplyEth{ value: 1 }();
        assertEq(cTokensMinted, 0.5 ether);

        assertEq(
            liquidityProviders.getCAssetBalance(address(this), address(cEtherToken)),
            0.5 ether
        );

        assertEq(cEtherToken.balanceOf(address(liquidityProviders)), 0.5 ether);
    }

    function testCannotSupplyEth_mint_fails() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        cEtherToken.setMintFail(true);

        hevm.expectRevert("cToken mint");

        liquidityProviders.supplyEth{ value: 1 }();
    }

    function testCannotSupplyEth_if_sanctioned() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.expectRevert("00017");

        hevm.deal(SANCTIONED_ADDRESS, 1);

        hevm.startPrank(SANCTIONED_ADDRESS);

        liquidityProviders.supplyEth{ value: 1 }();
    }

    function testCannotWithdrawEth_asset_not_whitelisted() public {
        hevm.expectRevert("00040");
        liquidityProviders.withdrawEth(1);
    }

    function testWithdrawEth_works() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.startPrank(NOT_ADMIN);

        hevm.deal(address(liquidityProviders), 0);
        hevm.deal(address(NOT_ADMIN), 1);

        uint256 startingBalance = NOT_ADMIN.balance;

        liquidityProviders.supplyEth{ value: 1 }();

        uint256 cTokensBurnt = liquidityProviders.withdrawEth(1);
        assertEq(cTokensBurnt, 1 ether);

        assertEq(liquidityProviders.getCAssetBalance(NOT_ADMIN, address(cEtherToken)), 0);

        assertEq(address(liquidityProviders).balance, 0);
        assertEq(cEtherToken.balanceOf(address(liquidityProviders)), 0);

        assertEq(NOT_ADMIN.balance, startingBalance);
    }

    function testWithdrawEth_works_event() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.startPrank(NOT_ADMIN);
        hevm.deal(address(NOT_ADMIN), 1);

        liquidityProviders.supplyEth{ value: 1 }();

        hevm.expectEmit(true, false, false, true);

        emit EthWithdrawn(NOT_ADMIN, 1, 1 ether);

        liquidityProviders.withdrawEth(1);
    }

    function testCannotWithdrawEth_redeemUnderlyingFails() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.startPrank(NOT_ADMIN);
        hevm.deal(address(NOT_ADMIN), 1);

        liquidityProviders.supplyEth{ value: 1 }();

        cEtherToken.setRedeemUnderlyingFail(true);

        hevm.expectRevert("00038");

        liquidityProviders.withdrawEth(1);
    }

    function testCannotWithdrawEth_withdraw_more_than_account_has() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.startPrank(NOT_ADMIN);
        hevm.deal(address(NOT_ADMIN), 1);

        liquidityProviders.supplyEth{ value: 1 }();

        hevm.stopPrank();

        // deposit some funds from a different address
        hevm.startPrank(
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000001)
        );

        liquidityProviders.supplyEth{ value: 1 }();

        hevm.expectRevert("00034");

        liquidityProviders.withdrawEth(2);
    }

    function testWithdrawEth_regen_collective_event_emits_when_owner() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        hevm.startPrank(liquidityProviders.owner());
        hevm.deal(liquidityProviders.owner(), 100);
        liquidityProviders.supplyEth{ value: 100 }();
        hevm.stopPrank();

        hevm.warp(block.timestamp + 1 weeks);

        hevm.expectEmit(true, true, true, true);

        emit PercentForRegen(
            liquidityProviders.regenCollectiveAddress(),
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            1,
            1000000000000000000
        );

        hevm.startPrank(liquidityProviders.owner());
        liquidityProviders.withdrawEth(100);
    }

    function testCannotWithdrawEth_if_sanctioned() public {
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );
        liquidityProviders.setMaxCAssetBalance(address(cEtherToken), 2**256 - 1);

        liquidityProviders.pauseSanctions();

        hevm.deal(SANCTIONED_ADDRESS, 1);

        hevm.prank(SANCTIONED_ADDRESS);
        liquidityProviders.supplyEth{ value: 1 }();

        liquidityProviders.unpauseSanctions();

        hevm.expectRevert("00017");
        hevm.prank(SANCTIONED_ADDRESS);
        liquidityProviders.withdrawEth(1);
    }
}
