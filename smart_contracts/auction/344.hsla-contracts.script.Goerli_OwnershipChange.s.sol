pragma solidity ^0.8.13;

import "forge-std/Script.sol";

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

contract OwnershipChangeScript is Script {
    address lendingImplementation = 0xD9629D75827832609A968b46f114a9eaabe5C35D;
    address offersImplementation = 0x7f634F43180C22b6A808d80Dd86A2420904c390F;
    address liquidityImplementation = 0x5A0cFdD291a51B2f2A3C39A43DE3460E629A93Dd;
    address sigLendingImplementation = 0xbAE015B359d6d78509011da06E7B105310203F9b;

    address lendingProxyAdmin = 0xe4cFbd689E49c8465Ef5AFAb25aF9702dD9Ce0aB;
    address offersProxyAdmin = 0xC89F61650f54f5FD7ca2559082b2bE363915BD57;
    address liquidityProxyAdmin = 0x3bb9DC0cEEd6fC9bC72D25275696F767B6b475b6;
    address sigLendingProxyAdmin = 0x512e7FC87D433030eA10dBC745853A4C77A2FAEf;

    address lendingProxy = 0x40dF7D76C59721b1E0b0e1cf92Dbd0A58D083De4;
    address offersProxy = 0x896A60e3f3457a3587F2ce30D812ffeDb7547EC7;
    address liquidityProxy = 0x084A7cE2eb1ea21777Df239550234EEb9D9ef47c;
    address sigLendingProxy = 0xf7c38F9b678cb96a6ee20448dab4a44B818dE2A6;

    function run() external {
        address goerliMultisigAddress = 0x213dE8CcA7C414C0DE08F456F9c4a2Abc4104028;

        vm.startBroadcast();

        // change ownership of implementation contracts
        IOwnership(liquidityImplementation).transferOwnership(goerliMultisigAddress);
        IOwnership(lendingImplementation).transferOwnership(goerliMultisigAddress);
        IOwnership(offersImplementation).transferOwnership(goerliMultisigAddress);
        IOwnership(sigLendingImplementation).transferOwnership(goerliMultisigAddress);

        // change ownership of proxies
        IOwnership(lendingProxy).transferOwnership(goerliMultisigAddress);
        IOwnership(offersProxy).transferOwnership(goerliMultisigAddress);
        IOwnership(liquidityProxy).transferOwnership(goerliMultisigAddress);
        IOwnership(sigLendingProxy).transferOwnership(goerliMultisigAddress);

        // change ownership of proxyAdmin
        IOwnership(lendingProxyAdmin).transferOwnership(goerliMultisigAddress);
        IOwnership(offersProxyAdmin).transferOwnership(goerliMultisigAddress);
        IOwnership(liquidityProxyAdmin).transferOwnership(goerliMultisigAddress);
        IOwnership(sigLendingProxyAdmin).transferOwnership(goerliMultisigAddress);

        vm.stopBroadcast();
    }
}
