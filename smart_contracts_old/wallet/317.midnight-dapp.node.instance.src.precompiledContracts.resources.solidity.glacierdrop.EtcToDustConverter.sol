pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../utils/SafeMath.sol";

// Ideally the conversion rate should be a float division:
//      totalAtomDistributed / totalUnlockedWei
// The problem is that Solidity doesn't support yet floating point operations, so doing the above calculation
// results in some value loss
// Given a user with X wei, he will receive:
//       (X * totalAtomDistributed) / totalUnlockedWei
contract EtcToDustConverter {
    using SafeMath for uint256;

    /// Converts a wei amount to the corresponding atom
    /// @param weiAmount ETC amount in wei that the user performing the GD has
    /// @param totalUnlockedWei during the whole unlocking period
    /// @param atomToBeDistributed among the users that unlocked ETC
    /// @return the amount of atom corresponding to the weiAmount the user had
    function convertEtherClassicToDust(uint256 weiAmount, uint256 totalUnlockedWei, uint256 atomToBeDistributed) pure public returns (uint256) {
        return weiAmount.mul(atomToBeDistributed).div(totalUnlockedWei);
    }

}