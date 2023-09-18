// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/proxy/Clones.sol";
import {ITraderClowderDelegateV1} from "./ITraderClowderDelegateV1.sol";

contract TraderClowderDelegateV1Factory is ITraderClowderDelegateV1 {
    address public immutable implementationContract;

    constructor(address _implementation) {
        implementationContract = _implementation;
    }

    function createNewClone(
        address[] memory accounts,
        uint256[] memory contributions,
        uint256 totalContributions
    ) external returns (address) {
        address clone = Clones.clone(implementationContract);
        ITraderClowderDelegateV1(clone).createNewClone(
            accounts,
            contributions,
            totalContributions
        );
        return clone;
    }
}
