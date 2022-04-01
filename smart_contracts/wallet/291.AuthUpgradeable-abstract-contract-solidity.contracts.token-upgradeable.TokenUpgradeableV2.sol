// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../access-upgradeable/AuthUpgradeable.sol";

/**
 * @title Token Contract
 * @author Beau Williams (@beauwilliams)
 * @dev Smart contract for Token
 */


contract TokenUpgradeableV2 is Initializable, UUPSUpgradeable, ERC20Upgradeable, AuthUpgradeable {
    function initialize() initializer public {
      __UUPSUpgradeable_init();
      __AuthUpgradeable_init();
      __ERC20_init("TokenUpgradeable", "TKU");
    }

    function _authorizeUpgrade(address) internal override authorised {}


    function exampleUpgrade() external view authorised returns(string memory)  {
        return "upgraded";
    }
}
