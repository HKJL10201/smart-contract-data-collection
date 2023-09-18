pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "../src/Lending.sol";

contract LendingUpgradeScript is Script {
    NiftyApesLending lendingImplementation;

    function run() external {
        address mainnetMultisigAddress = 0xbe9B799D066A51F77d353Fc72e832f3803789362;

        vm.startBroadcast();

        // deploy and initialize implementation contracts
        lendingImplementation = new NiftyApesLending();
        lendingImplementation.initialize(address(0), address(0), address(0));

        // change ownership of implementation contracts
        lendingImplementation.transferOwnership(mainnetMultisigAddress);

        vm.stopBroadcast();
    }
}
