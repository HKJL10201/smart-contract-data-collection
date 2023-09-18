// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILottery.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ITicketNFT.sol";
import "./interfaces/IRewardNFT.sol";
import "./test/RewardNFT.sol";
import "./test/TicketNFT.sol";
import "hardhat/console.sol";

contract Lottery is Ownable, ILottery {
    using SafeERC20 for IERC20;

    uint256 public thresholdTicketCnt = 10;
    uint256 public maxBuyTicketCnt = 3;
    uint256 public ticketPrice;
    uint256 public lotteryId;
    uint256 public saleId;
    uint256 public totalSoldTickets;
    address public priceToken;
    address public ticketNFT;
    address public rewardNFT;

    address private swapToken;
    address private lotteryVault;
    IUniswapV2Router02 private router;
    uint256 private swapPercent;
    bool private isLocked = false;
    mapping(uint256 => lottery) private lotteries;

    modifier lock {
        require (isLocked == false, "locked");
        isLocked = true;
        _;
        isLocked = false;
    }

    constructor (
        uint256 ticketPrice_,
        uint256 swapPercent_,
        address priceToken_,
        address swapToken_,
        address lotteryVault_,
        address router_
    ) {
        ticketPrice = ticketPrice_;
        swapPercent = swapPercent_;
        priceToken = priceToken_;
        swapToken = swapToken_;
        lotteryVault = lotteryVault_;
        router = IUniswapV2Router02(router_);
        ticketNFT = address(new TicketNFT("Ticket", "TNT"));
        rewardNFT = address(new RewardNFT("RewardNFT", "RWNT"));

        emit CreateTicketNFT(ticketNFT);
        emit CreateRewardNFT(rewardNFT);
    }

    /// @inheritdoc	ILottery
    function modifyTicketPrice(uint256 newTicketPrice_) external override onlyOwner {
        ticketPrice = newTicketPrice_;        
    }

    /// @inheritdoc	ILottery
    function modifySwapPercent(uint256 newSwapPercent_) external override onlyOwner {
        swapPercent = newSwapPercent_;
    }

    /// @inheritdoc	ILottery
    function modifyMaxBuyTicketCnt(uint256 newCnt_) external override onlyOwner {
        maxBuyTicketCnt = newCnt_;
    }

    /// @inheritdoc	ILottery
    function modifyThresholdTicketCnt(uint256 newThreshold_) external override onlyOwner {
        thresholdTicketCnt = newThreshold_;
    }

    /// @inheritdoc	ILottery
    function leftTicketCnt() external view override returns (uint256) {
        lottery memory curLottery = lotteries[lotteryId];
        uint256 leftTicketcnt = thresholdTicketCnt - curLottery.index;
        return (leftTicketcnt >= maxBuyTicketCnt ? maxBuyTicketCnt : leftTicketcnt);
    }

    /// @inheritdoc	ILottery
    function getWinner(uint256 lotteryId_) external view override returns (address) {
        require (lotteryId_ < lotteryId, "not finished yet");
        return lotteries[lotteryId_].winner;
    }

    /// @inheritdoc	ILottery
    function buyTicket(uint256 amount_) external lock override {
        address buyer = msg.sender;
        require (buyer != address(0), "invalid address");
        require (
            amount_ <= maxBuyTicketCnt &&
            lotteries[lotteryId].index + amount_ <= thresholdTicketCnt, 
            "exceeds max amount"
        );

        uint256 price = amount_ * ticketPrice;
        IERC20(priceToken).safeTransferFrom(buyer, address(this), price);

        lottery storage curLottery = lotteries[lotteryId];
        curLottery.index += amount_;
        totalSoldTickets += amount_;
        for (uint256 i = 0; i < amount_; i ++) {
            curLottery.holders.push(buyer);
        }
        saleId ++;
        ITicketNFT(ticketNFT).mintNFT(buyer, lotteryId, amount_);
        emit TicketSale(saleId, price, totalSoldTickets);

        _swapAndTransferToVault(price);
        if (curLottery.index == thresholdTicketCnt) {
            _chooseWinnerAndGiveReward();
            lotteryId ++;
            emit CreatedLottery(lotteryId);
        }
    }

    /// @notice Swap price token to specific token and transfer it to vault address.
    /// @param amount_ Amount of price token.
    function _swapAndTransferToVault(uint256 amount_) internal {
        uint256 amountToSwap = amount_ * swapPercent / 100;
        address[] memory path = new address[](2);
        path[0] = priceToken;
        path[1] = swapToken;
        IERC20(priceToken).safeApprove(address(router), amountToSwap);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSwap, 
            0, 
            path, 
            lotteryVault, 
            block.timestamp
        );

        emit SwappedPriceTokens(saleId, amountToSwap);   
    }

    /// @notice Choose winner and mint NFT to winner.
    function _chooseWinnerAndGiveReward() internal {
        uint256 winnerIdx = _random() % thresholdTicketCnt;
        address winner = lotteries[lotteryId].holders[winnerIdx];
        lotteries[lotteryId].winner = winner;
        IRewardNFT(rewardNFT).mintNFT(winner);
        emit WinnerForLottery(winner, lotteryId);
    }

    /// @notice generate radom number based on block's difficulty, timestamp, lotteryId, thresholdTicketCnt
    function _random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, lotteryId, thresholdTicketCnt)));
    }
}