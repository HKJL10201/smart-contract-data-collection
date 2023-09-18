// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.2;

import {InitialVoiceCreditProxy} from "maci-contracts/contracts/initialVoiceCreditProxy/InitialVoiceCreditProxy.sol";
import {SignUpGatekeeper} from "maci-contracts/contracts/gatekeepers/SignUpGatekeeper.sol";
import {MACI} from "maci-contracts/contracts/MACI.sol";

/*
 * This is the most simple contract for implementing MACI
 */
contract QuadraticVoting is InitialVoiceCreditProxy, SignUpGatekeeper {
    uint256 public budget = 100;

    function setMaciInstance(MACI _maci) public override {}

    /*
     * Registers the user without any restrictions.
     */
    function register(address, bytes memory) public override {}

    /*
     * Constant initial voice credits
     */
    function getVoiceCredits(address, bytes memory)
        public
        view
        override
        returns (uint256)
    {
        return budget;
    }
}
