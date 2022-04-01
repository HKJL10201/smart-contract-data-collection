pragma solidity ^0.8.2;
// SPDX-License-Identifier: Apache License 2.0
import "../utils/SafeMath.sol";

contract PoWTargetCalculator {
    using SafeMath for uint256;

    struct BalanceTimeBound {
        uint256 balanceBound;
        uint timeBound;
    }

    // it's ~ max balance which won't overflow uint256 during computation in solidity
    uint256 private constant maxBalance = 321644692325878320621030513913021966259083290738890455665159955577536471;

    function calculateTarget(uint256 balance, uint256 baseTarget, uint256 unlockingStartBlock, uint256 unlockingStopBlock) view public returns (uint256) {
        require(balance <= maxBalance, "Given balance is higher than max supported balance");
        uint256 estimatedTime = estimateTimeToMineHash(balance);
        (uint256 cNumerator, uint256 cDenominator) = calculateDifficultyCoefficient(unlockingStartBlock, unlockingStopBlock);
        uint256 difficulty = estimatedTime.mul(cNumerator).div(cDenominator);
        return baseTarget.div(difficulty);
    }

    function estimateTimeToMineHash(uint256 balance) pure private returns (uint256 timeToMineHash) {
        // can't instantiate as a state variable
        // balanceTimeBounds aka difficultyBounds and algorithm taken from https://github.com/Roman-Oliynykov/puzzle_complexity/blob/master/puzzle_complexity.cpp
        BalanceTimeBound[12] memory balanceTimeBounds = [BalanceTimeBound(0, 6 seconds),
            BalanceTimeBound(1 ether, 12 seconds),
            BalanceTimeBound(10 ether, 1 minutes),
            BalanceTimeBound(100 ether, 10 minutes),
            BalanceTimeBound(1000 ether, 60 minutes),
            BalanceTimeBound(10000 ether, 90 minutes),
            BalanceTimeBound(50000 ether, 120 minutes),
            BalanceTimeBound(100000 ether, 150 minutes),
            BalanceTimeBound(200000 ether, 180 minutes),
            BalanceTimeBound(1000000 ether, 240 minutes),
            BalanceTimeBound(10000000 ether, 600 minutes),
            BalanceTimeBound(maxBalance, 700 minutes)];

        if(balance == maxBalance) {
            BalanceTimeBound memory floor = balanceTimeBounds[balanceTimeBounds.length - 2];
            BalanceTimeBound memory ceil = balanceTimeBounds[balanceTimeBounds.length - 1];

            return powEstimatedTimeRequiredLinearInterpolation(balance, floor.balanceBound, floor.timeBound, ceil.balanceBound, ceil.timeBound);
        } else {
            for (uint i = 0; i < balanceTimeBounds.length; i++) {
                if(balance < balanceTimeBounds[i].balanceBound) {
                    BalanceTimeBound memory floor = balanceTimeBounds[i - 1];
                    BalanceTimeBound memory ceil = balanceTimeBounds[i];

                    return powEstimatedTimeRequiredLinearInterpolation(balance, floor.balanceBound, floor.timeBound, ceil.balanceBound, ceil.timeBound);
                }
            }
        }
    }

    // It's evaluating the passed balance on the linear interpolation of the 2 given bounds
    function powEstimatedTimeRequiredLinearInterpolation(
                            uint256 balance,
                            uint256 floorBalanceBound,
                            uint floorTimeBound,
                            uint256 ceilBalanceBound,
                            uint ceilTimeBound) pure private returns (uint256) {
        uint256 a1 = ceilTimeBound.sub(floorTimeBound);
        uint256 a2 = ceilBalanceBound.sub(floorBalanceBound);
        // ((balance * a1) + (a2 * floorTimeBound) - (floorBalanceBound * a1) )
        uint256 numerator = balance.mul(a1).add(a2.mul(floorTimeBound)).sub(floorBalanceBound.mul(a1));
        return numerator.div(a2);
    }

    // formula for c factor (difficulty coefficient):
    // k - an increasing work coefficient (k=1.5),
    // hs - start block of the unlocking period,
    // hc - current block of the unlocking period,
    // hf - final block of the unlocking period.
    // (k-1) / (hf-hs) * (hc-hs) + 1  =>
    // (k-1) * (hc-hs) / (hf-hs) + 1 => k = 1.5
    // (hc-hs) / (2 * (hf-hs)) + 1 => 1 = denominator / denominator
    // ((hc-hs) + (2 * (hf-hs)) / (2 * (hf-hs))
    // return fraction as (numerator, denominator)
    // * remember that block.number should be between hs and hf (in the unlock phase)
    function calculateDifficultyCoefficient(uint256 hs, uint256 hf) view private returns (uint256, uint256) {
        uint256 denominator = hf.sub(hs).mul(2);
        uint256 numerator = block.number.sub(hs) + denominator;
        return (numerator, denominator);
    }
}