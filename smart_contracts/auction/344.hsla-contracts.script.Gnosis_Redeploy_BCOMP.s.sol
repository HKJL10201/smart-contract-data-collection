// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";

import "../src/compound-contracts/Governance/Comp.sol";

contract BCOMPDeploymentScript is Script {
    Comp bComp;

    function run() external {
        // Gnosis Addresses
        address gnosisMultisigAddress = 0xA407aD41B5703432823f3694f857097542812E5a;

        vm.startBroadcast();

        bComp = new Comp(gnosisMultisigAddress);

        vm.stopBroadcast();
    }
}
