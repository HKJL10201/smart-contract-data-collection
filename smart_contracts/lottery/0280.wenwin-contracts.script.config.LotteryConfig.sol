// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/Script.sol";
import "src/interfaces/IReferralSystem.sol";
import "src/interfaces/IRNSourceController.sol";
import "src/Lottery.sol";

contract LotteryConfig is Script {
    using Strings for uint8;

    function getLottery(
        IERC20 rewardToken,
        uint256 playerRewardFirstDraw,
        uint256 playerRewardDecrease,
        uint256[] memory rewardsToReferrersPerDraw
    )
        internal
        returns (Lottery lottery)
    {
        uint8 selectionSize = uint8(vm.envUint("LOTTERY_SELECTION_SIZE"));

        lottery = new Lottery(
            LotterySetupParams(
                rewardToken,
                LotteryDrawSchedule(
                    vm.envUint("LOTTERY_FIRST_DRAW_AT"),
                    vm.envUint("LOTTERY_DRAW_PERIOD"),
                    vm.envUint("LOTTERY_DRAW_COOL_DOWN_PERIOD")
                ),
                vm.envUint("LOTTERY_TICKET_PRICE"),
                selectionSize,
                uint8(vm.envUint("LOTTERY_SELECTION_MAX")),
                uint256(vm.envUint("LOTTERY_EXPECTED_PAYOUT")),
                getFixedRewards(selectionSize)
            ),
            playerRewardFirstDraw,
            playerRewardDecrease,
            rewardsToReferrersPerDraw,
            vm.envUint("SOURCE_MAX_FAILED_ATTEMPTS"),
            vm.envUint("SOURCE_MAX_REQUEST_DELAY")
        );
    }

    function getFixedRewards(uint8 selectionSize) private view returns (uint256[] memory) {
        uint256[] memory fixedRewards = new uint256[](selectionSize);
        for (uint8 i = 1; i < selectionSize; i++) {
            try vm.envUint(string(abi.encodePacked("LOTTERY_FIXED_REWARD_TIER_", i.toString()))) returns (
                uint256 reward
            ) {
                fixedRewards[i] = reward;
            } catch {
                fixedRewards[i] = 0;
            }
        }
        return fixedRewards;
    }
}
