pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Offers.sol";

contract OffersUpgradeScript is Script {
    NiftyApesOffers offersImplementation;

    function run() external {
        address mainnetMultisigAddress = 0xbe9B799D066A51F77d353Fc72e832f3803789362;

        vm.startBroadcast();

        // deploy and initialize implementation contracts
        offersImplementation = new NiftyApesOffers();
        offersImplementation.initialize(address(0));

        // change ownership of implementation contracts
        offersImplementation.transferOwnership(mainnetMultisigAddress);

        vm.stopBroadcast();
    }
}
