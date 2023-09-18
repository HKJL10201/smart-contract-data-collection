// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./Lottery.sol";

/**
 * @title Lotto lottery contract with 4 numbers
 * Deployment sequence:
 * 1. Deploy LotteryNFT
 * 2. Deploy the current contract LotteryGOC
 * 3. Set LotteryNFT.setAdmin()
 * 4. Set GOT.addAdmin()
 * Operation sequence:
 * 1. Purchase buy() || multiBuy()
 * 2. Enter the lottery stage enterDrawingPhase()
 * 3. Drawing()
 * 4. Reset reset()
 */
contract LotteryGOC is Lottery {
    /// @notice GOT address
    address public constant GOT = 0x6AF26474015a6bF540C79b77a6155b67900879D9;
    /// @notice GOC address is used to buy lottery ticket token
    address public constant GOC = 0x8A419Ef4941355476cf04933E90Bf3bbF2F73814;

    /**
     * @dev constructor
     * @param _lotteryNFT Lottery NFT address
     */
    constructor(ILotteryNFT _lotteryNFT) Lottery(_lotteryNFT, GOC) {
        // Approve unlimited GOC
        IERC20(GOC).approve(GOSWAP_ROUTER, type(uint128).max);
        // minimum selling price
        minPrice =  1000000000000000000 ;
    }

    /**
     * @dev reset
     */
    function reset() public override onlyAdmin {
        super.reset();
        // Destroyed amount = Last total bonus * (100-first prize + second prize + third prize) allocation ratio / 100
        uint8 burnAllocation = uint8(uint8(100) - allocation[0] - allocation[1] - allocation[2]);
        uint256 burnAmount = getTotalRewards(issueIndex - 1) * (burnAllocation) / (100);
        if (burnAmount > 0) {
            // Transaction path GOC=>GOT
            address[] memory path = new address[](2);
            path[0] = GOC;
            path[1] = GOT;
            // Call the routing contract to exchange GOT with GOC
            Uni(GOSWAP_ROUTER).swapExactTokensForTokens(burnAmount, uint256(0), path, address(this), block.timestamp +  (1800));
        }
        // GOT balance of the current contract
        uint256 GOTBalance = IERC20(GOT).balanceOf(address(this));
        if (GOTBalance > 0) {
            // Destroy GOT
            IGOT (GOT). burn (GOTBalance);
        }
    }
}