pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "@openzeppelin-norm/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-norm/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/interfaces/niftyapes/lending/ILending.sol";
import "../src/interfaces/niftyapes/offers/IOffers.sol";
import "../src/interfaces/niftyapes/liquidity/ILiquidity.sol";
import "../src/interfaces/niftyapes/sigLending/ISigLending.sol";
import "../src/interfaces/ownership.sol";

import "../src/Liquidity.sol";
import "../src/Offers.sol";
import "../src/SigLending.sol";
import "../src/Lending.sol";

contract DeployNiftyApesScript is Script {
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

    function run() external {
        address compContractAddress = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

        vm.startBroadcast();

        // deploy and initialize implementation contracts
        liquidityImplementation = new NiftyApesLiquidity();
        liquidityImplementation.initialize(address(0));

        offersImplementation = new NiftyApesOffers();
        offersImplementation.initialize(address(0));

        sigLendingImplementation = new NiftyApesSigLending();
        sigLendingImplementation.initialize(address(0));

        lendingImplementation = new NiftyApesLending();
        lendingImplementation.initialize(address(0), address(0), address(0));

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
        liquidity.initialize(address(compContractAddress));
        offers.initialize(address(liquidity));
        sigLending.initialize(address(offers));
        lending.initialize(address(liquidity), address(offers), address(sigLending));

        // associate proxies
        liquidity.updateLendingContractAddress(address(lending));

        offers.updateLendingContractAddress(address(lending));
        offers.updateSigLendingContractAddress(address(sigLending));

        sigLending.updateLendingContractAddress(address(lending));

        // Goerli Addresses
        address daiToken = 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60;
        address cDAIToken = 0x822397d9a55d0fefd20F5c4bCaB33C5F65bd28Eb;
        address ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address cEtherToken = 0x20572e4c090f15667cF7378e16FaD2eA0e2f3EfF;

        // DAI
        liquidity.setCAssetAddress(daiToken, cDAIToken);

        uint256 cDAIAmount = liquidity.assetAmountToCAssetAmount(daiToken, type(uint128).max);

        liquidity.setMaxCAssetBalance(cDAIToken, cDAIAmount);

        // ETH
        liquidity.setCAssetAddress(ETH_ADDRESS, cEtherToken);

        uint256 cEtherAmount = liquidity.assetAmountToCAssetAmount(ETH_ADDRESS, type(uint128).max);

        liquidity.setMaxCAssetBalance(cEtherToken, cEtherAmount);

        // pauseSanctions for Goerli as Chainalysis contacts doent exists there
        liquidity.pauseSanctions();
        lending.pauseSanctions();

        vm.stopBroadcast();
    }
}
