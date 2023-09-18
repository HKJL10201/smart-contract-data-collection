// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SolidStateDiamond} from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";
import {ISimplicyWalletDiamond} from "./ISimplicyWalletDiamond.sol";

contract SimplicyWalletDiamond is ISimplicyWalletDiamond, SolidStateDiamond {
    /**
     * @notice return the current version of the diamond
     */
    function version()
        public
        pure
        override(ISimplicyWalletDiamond)
        returns (string memory)
    {
        return "0.0.1";
    }
}
