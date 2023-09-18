pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Lending.sol";

contract LendingUpgradeScript is Script {
    NiftyApesLending lendingImplementation;

    function run() external {
        address goerliMultisigAddress = 0x213dE8CcA7C414C0DE08F456F9c4a2Abc4104028;

        vm.startBroadcast();

        // deploy and initialize implementation contracts
        lendingImplementation = new NiftyApesLending();
        lendingImplementation.initialize(address(0), address(0), address(0));

        // change ownership of implementation contracts
        lendingImplementation.transferOwnership(goerliMultisigAddress);

        vm.stopBroadcast();
    }
}
