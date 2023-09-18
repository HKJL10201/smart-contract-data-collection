// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20Upgradeable.sol";
import "../../interfaces/compound/ICERC20.sol";
import "../../interfaces/compound/ICEther.sol";
import "../../Lending.sol";
import "../../Liquidity.sol";
import "../../Offers.sol";
import "../../SigLending.sol";
import "../../interfaces/niftyapes/lending/ILendingEvents.sol";
import "../../interfaces/niftyapes/liquidity/ILiquidityEvents.sol";
import "../common/BaseTest.sol";
import "../mock/CERC20Mock.sol";
import "../mock/CEtherMock.sol";
import "../mock/ERC20Mock.sol";

import "@openzeppelin-norm/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-norm/contracts/proxy/transparent/ProxyAdmin.sol";

import "../../interfaces/niftyapes/lending/ILending.sol";
import "../../interfaces/niftyapes/offers/IOffers.sol";
import "../../interfaces/niftyapes/liquidity/ILiquidity.sol";
import "../../interfaces/niftyapes/sigLending/ISigLending.sol";

contract AdminUnitTest is BaseTest, ILendingEvents, ILiquidityEvents {
    ERC20Mock daiToken;
    CERC20Mock cDAIToken;
    CEtherMock cEtherToken;

    NiftyApesLending lendingImplementation;
    NiftyApesOffers offersImplementation;
    NiftyApesLiquidity liquidityImplementation;
    NiftyApesSigLending sigLendingImplementation;

    ProxyAdmin lendingProxyAdmin;
    ProxyAdmin offersProxyAdmin;
    ProxyAdmin liquidityProxyAdmin;
    ProxyAdmin sigLendingProxyAdmin;

    TransparentUpgradeableProxy lendingProxy;
    TransparentUpgradeableProxy offersProxy;
    TransparentUpgradeableProxy liquidityProxy;
    TransparentUpgradeableProxy sigLendingProxy;

    ILending niftyApes;
    IOffers offersContract;
    ILiquidity liquidityProviders;
    ISigLending sigLendingAuction;

    address compContractAddress = 0xbbEB7c67fa3cfb40069D19E598713239497A3CA5;

    bool acceptEth;

    address constant NOT_ADMIN = address(0x5050);

    receive() external payable {
        require(acceptEth, "acceptEth");
    }

    function setUp() public {
        liquidityImplementation = new NiftyApesLiquidity();
        offersImplementation = new NiftyApesOffers();
        sigLendingImplementation = new NiftyApesSigLending();
        lendingImplementation = new NiftyApesLending();

        // deploy proxy admins
        lendingProxyAdmin = new ProxyAdmin();
        offersProxyAdmin = new ProxyAdmin();
        liquidityProxyAdmin = new ProxyAdmin();
        sigLendingProxyAdmin = new ProxyAdmin();

        // deploy proxies
        lendingProxy = new TransparentUpgradeableProxy(
            address(lendingImplementation),
            address(lendingProxyAdmin),
            bytes("")
        );
        offersProxy = new TransparentUpgradeableProxy(
            address(offersImplementation),
            address(offersProxyAdmin),
            bytes("")
        );
        liquidityProxy = new TransparentUpgradeableProxy(
            address(liquidityImplementation),
            address(liquidityProxyAdmin),
            bytes("")
        );

        sigLendingProxy = new TransparentUpgradeableProxy(
            address(sigLendingImplementation),
            address(sigLendingProxyAdmin),
            bytes("")
        );

        // declare interfaces
        niftyApes = ILending(address(lendingProxy));
        liquidityProviders = ILiquidity(address(liquidityProxy));
        offersContract = IOffers(address(offersProxy));
        sigLendingAuction = ISigLending(address(sigLendingProxy));

        // initialize proxies
        liquidityProviders.initialize(address(compContractAddress));
        offersContract.initialize(address(liquidityProviders));
        sigLendingAuction.initialize(address(offersContract));
        niftyApes.initialize(
            address(liquidityProviders),
            address(offersContract),
            address(sigLendingAuction)
        );

        daiToken = new ERC20Mock();
        daiToken.initialize("USD Coin", "DAI");
        cDAIToken = new CERC20Mock();
        cDAIToken.initialize(daiToken);
        liquidityProviders.setCAssetAddress(address(daiToken), address(cDAIToken));
        cEtherToken = new CEtherMock();
        cEtherToken.initialize();

        acceptEth = true;
    }

    function testSetCAddressMapping_returns_null_address() public {
        assertEq(
            liquidityProviders.assetToCAsset(address(0x0000000000000000000000000000000000000001)),
            address(0x0000000000000000000000000000000000000000)
        );
    }

    function testSetCAddressMapping_can_be_set_by_owner() public {
        hevm.expectEmit(false, false, false, true);

        emit AssetToCAssetSet(
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000002)
        );

        liquidityProviders.setCAssetAddress(
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000002)
        );

        assertEq(
            liquidityProviders.assetToCAsset(address(0x0000000000000000000000000000000000000001)),
            address(0x0000000000000000000000000000000000000002)
        );
    }

    function testCannotSetCAddressMapping_can_not_be_set_by_non_owner() public {
        hevm.startPrank(NOT_ADMIN);

        hevm.expectRevert("Ownable: caller is not the owner");
        liquidityProviders.setCAssetAddress(
            address(0x0000000000000000000000000000000000000001),
            address(0x0000000000000000000000000000000000000002)
        );
    }

    function testCannotUpdateProtocolInterestBps_not_owner() public {
        hevm.startPrank(NOT_ADMIN);
        hevm.expectRevert("Ownable: caller is not the owner");
        niftyApes.updateProtocolInterestBps(1);
    }

    function testCannotUpdateProtocolInterestBps_max_fee() public {
        hevm.expectRevert("00002");
        niftyApes.updateProtocolInterestBps(1001);
    }

    function testUpdateProtocolInterestBps_owner() public {
        assertEq(niftyApes.protocolInterestBps(), 0);
        hevm.expectEmit(false, false, false, true);

        emit ProtocolInterestBpsUpdated(0, 1);
        niftyApes.updateProtocolInterestBps(1);
        assertEq(niftyApes.protocolInterestBps(), 1);
    }

    function testCannotUpdateOriginationPremiumLenderBps_not_owner() public {
        hevm.startPrank(NOT_ADMIN);
        hevm.expectRevert("Ownable: caller is not the owner");
        niftyApes.updateOriginationPremiumLenderBps(1);
    }

    function testCannotUpdateOriginationPremiumLenderBps_max_fee() public {
        hevm.expectRevert("00002");
        niftyApes.updateOriginationPremiumLenderBps(1001);
    }

    function testUpdateOriginationPremiumLenderBps_owner() public {
        assertEq(niftyApes.originationPremiumBps(), 25);
        hevm.expectEmit(false, false, false, true);

        emit OriginationPremiumBpsUpdated(25, 1);
        niftyApes.updateOriginationPremiumLenderBps(1);
        assertEq(niftyApes.originationPremiumBps(), 1);
    }

    function testCannotUpdateGasGriefingPremiumBps_not_owner() public {
        hevm.startPrank(NOT_ADMIN);
        hevm.expectRevert("Ownable: caller is not the owner");
        niftyApes.updateGasGriefingPremiumBps(1);
    }

    function testCannotUpdateGasGriefingPremiumBps_max_fee() public {
        hevm.expectRevert("00002");
        niftyApes.updateGasGriefingPremiumBps(1001);
    }

    function testUpdateGasGriefingPremiumBps_owner() public {
        assertEq(niftyApes.gasGriefingPremiumBps(), 25);
        hevm.expectEmit(false, false, false, true);

        emit GasGriefingPremiumBpsUpdated(25, 1);
        niftyApes.updateGasGriefingPremiumBps(1);
        assertEq(niftyApes.gasGriefingPremiumBps(), 1);
    }

    function testCannotUpdateRegenCollectiveBpsOfRevenue_not_owner() public {
        hevm.startPrank(NOT_ADMIN);
        hevm.expectRevert("Ownable: caller is not the owner");
        liquidityProviders.updateRegenCollectiveBpsOfRevenue(1);
    }

    function testCannotUpdateRegenCollectiveBpsOfRevenue_max_fee() public {
        hevm.expectRevert("00002");
        liquidityProviders.updateRegenCollectiveBpsOfRevenue(1001);
    }

    function testCannotUpdateRegenCollectiveBpsOfRevenue_mustBeGreater() public {
        hevm.expectRevert("00039");
        liquidityProviders.updateRegenCollectiveBpsOfRevenue(1);
    }

    function testUpdateRegenCollectiveBpsOfRevenue_works() public {
        assertEq(liquidityProviders.regenCollectiveBpsOfRevenue(), 100);
        hevm.expectEmit(true, false, false, true);

        emit RegenCollectiveBpsOfRevenueUpdated(100, 101);
        liquidityProviders.updateRegenCollectiveBpsOfRevenue(101);
        assertEq(liquidityProviders.regenCollectiveBpsOfRevenue(), 101);
    }
}
