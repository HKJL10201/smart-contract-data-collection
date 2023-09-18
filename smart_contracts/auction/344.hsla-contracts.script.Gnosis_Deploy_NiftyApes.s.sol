pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "@openzeppelin-norm/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-norm/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/interfaces/niftyapes/lending/ILending.sol";
import "../src/interfaces/niftyapes/offers/IOffers.sol";
import "../src/interfaces/niftyapes/liquidity/ILiquidity.sol";
import "../src/interfaces/niftyapes/sigLending/ISigLending.sol";
import "../src/interfaces/Ownership.sol";

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
        //to update once compound deployed on gnosis
        address bCompContractAddress = 0x267a3d54dF81207D951C495deBd4933Bc5689538;
        address gnosisMultisigAddress = 0xA407aD41B5703432823f3694f857097542812E5a;

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
        liquidity.initialize(address(bCompContractAddress));
        offers.initialize(address(liquidity));
        sigLending.initialize(address(offers));
        lending.initialize(address(liquidity), address(offers), address(sigLending));

        // associate proxies
        liquidity.updateLendingContractAddress(address(lending));

        offers.updateLendingContractAddress(address(lending));
        offers.updateSigLendingContractAddress(address(sigLending));

        sigLending.updateLendingContractAddress(address(lending));

        // Goerli Addresses
        address wxDaiToken = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
        address bwxDaiToken = 0x67ECb3C872941241F21839Ec9111C7Ca6678342e;

        // DAI
        liquidity.setCAssetAddress(wxDaiToken, bwxDaiToken);

        uint256 bwxDAIAmount = liquidity.assetAmountToCAssetAmount(wxDaiToken, type(uint128).max);

        liquidity.setMaxCAssetBalance(bwxDaiToken, bwxDAIAmount);

        // pauseSanctions for Gnosis as Chainalysis contacts doesnt exists there
        liquidity.pauseSanctions();
        lending.pauseSanctions();

        // change ownership of implementation contracts
        liquidityImplementation.transferOwnership(gnosisMultisigAddress);
        lendingImplementation.transferOwnership(gnosisMultisigAddress);
        offersImplementation.transferOwnership(gnosisMultisigAddress);
        sigLendingImplementation.transferOwnership(gnosisMultisigAddress);

        // change ownership of proxies
        IOwnership(address(lendingProxy)).transferOwnership(gnosisMultisigAddress);
        IOwnership(address(offersProxy)).transferOwnership(gnosisMultisigAddress);
        IOwnership(address(liquidityProxy)).transferOwnership(gnosisMultisigAddress);
        IOwnership(address(sigLendingProxy)).transferOwnership(gnosisMultisigAddress);

        // change ownership of proxyAdmin
        lendingProxyAdmin.transferOwnership(gnosisMultisigAddress);
        offersProxyAdmin.transferOwnership(gnosisMultisigAddress);
        liquidityProxyAdmin.transferOwnership(gnosisMultisigAddress);
        sigLendingProxyAdmin.transferOwnership(gnosisMultisigAddress);

        vm.stopBroadcast();
    }
}
