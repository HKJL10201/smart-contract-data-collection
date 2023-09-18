// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "./LotteryEchidna.sol";

contract LotteryEchidnaProperty is LotteryEchidna {
    function echidnaCheckRewardTokenLotteryBalance() public view returns (bool) {
        return (rewardToken.balanceOf(address(lottery)) >= rewardTokenLotteryBalance);
    }

    function echidnaCheckDrawExecutionInProgress() public view returns (bool) {
        return (lottery.drawExecutionInProgress() == drawExecutionInProgressEchidna);
    }

    function echidnaCheckDrawId() public view returns (bool) {
        return (lottery.currentDraw() == drawIdEchidna);
    }

    function echidnaCheckLotteryTokenBalance() public view returns (bool) {
        return (lotteryToken.balanceOf(address(this)) >= lotteryToken.INITIAL_SUPPLY());
    }

    function echidnaCheckStakingTotalSupply() public view returns (bool) {
        return (stakingEchidna.stakingContract().totalSupply() == stakingEchidna.stakingTotalSupply());
    }

    function echidnaCheckSumOfRewards() public view returns (bool) {
        return (stakingEchidna.sumOfRewards() <= stakingEchidna.getMaxRewardAmount());
    }

    function echidnaValidateRewardWonType() public view returns (bool) {
        uint128 currentDraw = lottery.currentDraw();
        for (uint128 counter = 0; counter < currentDraw; ++counter) {
            if (validateRewardWonType(counter) == false) {
                return false;
            }
        }
        return true;
    }

    function echidnaCheckNumberOfClaimedTickets() public view returns (bool) {
        return checkNumberOfClaimedTickets();
    }
}
