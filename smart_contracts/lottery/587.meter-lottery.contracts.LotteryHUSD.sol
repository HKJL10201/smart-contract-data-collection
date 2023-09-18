// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./Lottery.sol";

/**
 * @title Lotto lottery contract with 4 numbers
 * Deployment sequence:
 * 1. Deploy LotteryNFT
 * 2. Deploy the current contract LotteryHUSD
 * 3. Set LotteryNFT.setAdmin()
 * Operation sequence:
 * 1. Purchase buy() || multiBuy()
 * 2. Enter the lottery stage enterDrawingPhase()
 * 3. Drawing()
 * 4. Reset reset()
 */
contract LotteryHUSD is Lottery {
    /// @notice HUSD address is used to purchase lottery tokens
    address public constant HUSD = 0x0298c2b32eaE4da002a15f36fdf7615BEa3DA047;
    /// @notice GOC address
    address public constant GOC = 0x271B54EBe36005A7296894F819D626161C44825C;
    /// @notice Lottery GOC address
    address public lotteryGOC;

    /**
     * @dev constructor
     * @param _lotteryNFT Lottery NFT address
     */
    constructor(ILotteryNFT _lotteryNFT, address _lotteryGOC) Lottery(_lotteryNFT, HUSD) {
        // set address
        lotteryGOC = _lotteryGOC;
        // Approve unlimited HUSD
        IERC20(GOC).approve(lotteryGOC, type(uint128).max);
        // Approve unlimited HUSD
        IERC20(HUSD).approve(GOSWAP_ROUTER, type(uint128).max);
        // minimum selling price
        minPrice =  100000000 ;
    }

    /**
     * @dev reset
     */
    function reset() public override onlyAdmin {
        super.reset();
        // Destroyed amount = Last total bonus * (100-first prize + second prize + third prize) allocation ratio / 100
        uint8 _allocation = uint8(uint8(100) - (allocation[0]) - (allocation[1]) - (allocation[2]));
        uint256 amount = getTotalRewards(issueIndex - 1) * (_allocation) / (100);
        if (amount > 0) {
            // Transaction path HUSD=>GOC
            address[] memory path = new address[](2);
            path[0] = HUSD;
            path[1] = GOC;
            // Call the routing contract to exchange HUSD for GOC
            Uni(GOSWAP_ROUTER).swapExactTokensForTokens(amount, uint256(0), path, address(this), block.timestamp + (1800));
        }
        // GOC balance of the current contract
        uint256 GOCBalance = IERC20(GOC).balanceOf(address(this));
        // GOC balance needs to be greater than the minimum price
        if (GOCBalance >= ILottery(lotteryGOC).minPrice()) {
            // buy GOC lottery
            ILottery(lotteryGOC).buy(GOCBalance, nullTicket);
        }
    }

    /**
     * @dev set LotteryGOC
     * @param _lotteryGOC lotteryGOC address
     */
    function setLotteryGOC(address _lotteryGOC) external onlyOwner {
        // If the lotteryGOC address is not 0
        if (lotteryGOC != address(0)) {
            // Cancel authorization
            IERC20(GOC).approve(lotteryGOC, uint256(0));
        }
        // set address
        lotteryGOC = _lotteryGOC;
        // Approve unlimited HUSD
        IERC20(GOC).approve(lotteryGOC,  type(uint128).max);
    }
}