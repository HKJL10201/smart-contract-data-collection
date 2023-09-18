// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin-norm/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-norm/contracts/proxy/transparent/ProxyAdmin.sol";

import "../../../interfaces/niftyapes/lending/ILending.sol";
import "../../../interfaces/niftyapes/offers/IOffers.sol";
import "../../../interfaces/niftyapes/liquidity/ILiquidity.sol";
import "../../../interfaces/niftyapes/sigLending/ISigLending.sol";

import "../../../Lending.sol";
import "../../../Liquidity.sol";
import "../../../Offers.sol";
import "../../../SigLending.sol";
import "./NFTAndERC20Fixtures.sol";

import "forge-std/Test.sol";

// deploy & initializes NiftyApes contracts
// connects them to one another
// adds cAssets for both ETH and DAI
// sets max cAsset balance for both to unint256 max
contract NiftyApesDeployment is Test, NFTAndERC20Fixtures {
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
    ILending lending;
    IOffers offers;
    ILiquidity liquidity;
    ISigLending sigLending;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(owner);

        // deploy and initialize implementation contracts
        liquidityImplementation = new NiftyApesLiquidity();
        liquidityImplementation.initialize(address(compToken));

        offersImplementation = new NiftyApesOffers();
        offersImplementation.initialize(address(liquidityImplementation));

        sigLendingImplementation = new NiftyApesSigLending();
        sigLendingImplementation.initialize(address(offersImplementation));

        lendingImplementation = new NiftyApesLending();
        lendingImplementation.initialize(
            address(liquidityImplementation),
            address(offersImplementation),
            address(sigLendingImplementation)
        );

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
        lending = ILending(address(lendingProxy));
        liquidity = ILiquidity(address(liquidityProxy));
        offers = IOffers(address(offersProxy));
        sigLending = ISigLending(address(sigLendingProxy));

        // initialize proxies
        liquidity.initialize(address(compToken));
        offers.initialize(address(liquidity));
        sigLending.initialize(address(offers));
        lending.initialize(address(liquidity), address(offers), address(sigLending));

        // associate proxies
        liquidity.updateLendingContractAddress(address(lending));

        offers.updateLendingContractAddress(address(lending));
        offers.updateSigLendingContractAddress(address(sigLending));

        sigLending.updateLendingContractAddress(address(lending));

        // set max balances
        liquidity.setCAssetAddress(ETH_ADDRESS, address(cEtherToken));
        liquidity.setMaxCAssetBalance(address(cEtherToken), ~uint256(0));

        liquidity.setCAssetAddress(address(daiToken), address(cDAIToken));
        liquidity.setMaxCAssetBalance(address(cDAIToken), ~uint256(0));

        // update protocol interest
        lending.updateProtocolInterestBps(100);
        lending.updateDefaultRefinancePremiumBps(25);

        if (!integration) {
            liquidity.pauseSanctions();
            lending.pauseSanctions();
        }

        vm.stopPrank();

        vm.label(address(0), "NULL !!!!! ");
    }
}
