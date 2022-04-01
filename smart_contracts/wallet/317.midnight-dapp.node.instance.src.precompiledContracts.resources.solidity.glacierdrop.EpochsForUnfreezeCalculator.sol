pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../utils/SafeMath.sol";

contract EpochsForUnfreezeCalculator {
    using SafeMath for uint256;

    // Calculation is done following two linear calculations:
    //  - If below the average balance then linearly between:
    //        Minimum balance -> number of epochs 1
    //        Average balance -> number of epochs TOTAL_EPOCHS / 2
    //  - If above or equal to the average balance then linearly between:
    //        Average balance -> number of epochs TOTAL_EPOCHS / 2
    //        Maximum balance -> number of epochs TOTAL_EPOCHS
    // Note: It's assumed that the number of epochs is an odd number
    function numberEpochsForFullUnfreeze(uint256 etcOwnerBalance,
                                         uint256 minimumUnlockedBalance,
                                         uint256 averageUnlockedBalance,
                                         uint256 maximumUnlockedBalance,
                                         uint256 totalEpochs) pure public returns (uint256) {
        uint256 halfEpochs = totalEpochs / 2;
        if(etcOwnerBalance == averageUnlockedBalance) {
            return halfEpochs;
        } else if(etcOwnerBalance < averageUnlockedBalance) {
            uint256 dividend = etcOwnerBalance.sub(minimumUnlockedBalance).mul(halfEpochs.sub(1));

            // Guaranteed to be over 0 as averageUnlockedBalance > etcOwnerBalance >= minimumUnlockedBalance
            uint256 divisor = averageUnlockedBalance.sub(minimumUnlockedBalance);

            uint256 epochsRequired = ceilDivision(dividend, divisor).add(1);
            return epochsRequired;
        } else {
            uint256 dividend = etcOwnerBalance.sub(averageUnlockedBalance).mul(halfEpochs);

            // Guaranteed to be over 0 as maximumUnlockedBalance >= etcOwnerBalance > averageUnlockedBalance
            uint256 divisor = maximumUnlockedBalance.sub(averageUnlockedBalance);

            uint256 epochsRequired = ceilDivision(dividend, divisor).add(halfEpochs);
            return epochsRequired;
        }
    }

    // Ceil function is not implemented in solidity so it has to be calculated through:
    //   ceil(x/y) = 1 + floor((x-1)/y)
    // Warning: This function throws an exception if divisor is 0
    function ceilDivision(uint256 dividend, uint256 divisor) internal pure returns (uint256) {
        if(dividend == 0 && divisor != 0) {
            return 0;
        } else {
            uint256 result = dividend.sub(1).div(divisor).add(1);
            return result;
        }
    }
}