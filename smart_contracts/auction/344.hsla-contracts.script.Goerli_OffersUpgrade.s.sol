pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Offers.sol";

contract OffersUpgradeScript is Script {
    NiftyApesOffers offersImplementation;

    function run() external {
        address goerliMultisigAddress = 0x213dE8CcA7C414C0DE08F456F9c4a2Abc4104028;

        vm.startBroadcast();

        // deploy and initialize implementation contracts
        offersImplementation = new NiftyApesOffers();
        offersImplementation.initialize(address(0));

        // change ownership of implementation contracts
        offersImplementation.transferOwnership(goerliMultisigAddress);

        vm.stopBroadcast();
    }
}
