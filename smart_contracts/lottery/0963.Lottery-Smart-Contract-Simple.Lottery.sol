pragma solidity ^0.5.0;

import "./chainlink/VRFConsumerBase.sol";

import "./ILotteryDao.sol";
import "./ILottery.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery is ILottery, VRFConsumerBase {
    using SafeMathChainlink for uint256;

    struct Purchase {
        uint256 ticketStart;
        uint256 ticketEnd;
    }

    struct Game {
        uint256 issuedTickets;
        uint256 totalPurchases;
        bool winnersExtracted;
        bool ongoing;
        address[] winners;
        uint256[] winningTickets;
        uint256[] prizes;
        bool[] rewardsRedeemed;

        mapping(address => uint256[]) players;
        mapping(uint256 => Purchase) purchases;
    }
    
    struct LinkVRF {
        bytes32 keyHash;
        uint256 fee;
    }

    ILotteryDao public dao;

    LinkVRF private link;

    uint256 public gameLength;
    mapping(uint256 => Game) public games;

    constructor()
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) public
    {
        dao = ILotteryDao(0x0aF9087FE3e8e834F3339FE4bEE87705e84Fd488);
        link.fee = 2e18;
        link.keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    }

    event GameStarted(uint256 indexed gameIndex, uint256[] prizes);
    event TicketsPurchase(address indexed sender, uint256 indexed purchaseId, uint256 indexed lotteryId, uint256 ticketStart, uint256 ticketEnd);
    event LotteryEnded(uint256 indexed lotteryId);
    event WinningTicketsSorted(uint256 indexed lotteryId, uint256[] winningTickets);
    event RewardRedeemed(address indexed recipient, uint256 indexed lotteryId, uint256 reward);

    modifier onlyDAO() {
        require(msg.sender == address(dao), "Lottery: sender isn't the DAO");
        _;
    }

    function gameIndex() public view returns (uint256) {
        return gameLength.sub(1);
    }

    function treasury() public view returns (address) {
        return dao.treasury();
    }

    function dollar() public view returns (IERC20) {
        return IERC20(dao.dollar());
    }

    function getWinners(uint256 gameIndex) external view returns(address[] memory) {
        return games[gameIndex].winners;
    }

    function getWinningTickets(uint256 gameIndex) external view returns(uint256[] memory) {
        return games[gameIndex].winningTickets;
    }

    function getPrizes(uint256 gameIndex) external view returns(uint256[] memory) {
        return games[gameIndex].prizes;
    }

    function getIssuedTickets(uint256 gameIndex) external view returns (uint256) {
        return games[gameIndex].issuedTickets;
    }

    function getRedeemedPrizes(uint256 gameIndex) external view returns(bool[] memory) {
        return games[gameIndex].rewardsRedeemed;
    }

    function isOngoing(uint256 gameIndex) external view returns(bool) {
        return games[gameIndex].ongoing;
    }

    function areWinnersExtracted(uint256 gameIndex) external view returns(bool) {
        return games[gameIndex].winnersExtracted;
    }

    function getTotalPurchases(uint256 gameIndex) external view returns(uint256) {
        return games[gameIndex].totalPurchases;
    }

    function getPlayerPurchaseIndexes(uint256 gameIndex, address player) external view returns(uint256[] memory) {
        return games[gameIndex].players[player];
    }

    function getPurchase(uint256 gameIndex, uint256 purchaseIndex) external view returns(uint256, uint256) {
        return (games[gameIndex].purchases[purchaseIndex].ticketStart, games[gameIndex].purchases[purchaseIndex].ticketEnd);
    }

    function newGame(uint256[] calldata prizes) external onlyDAO {   
        require(LINK.balanceOf(address(this)) >= link.fee, "Lottery: Insufficient link balance");

        if (gameLength > 0)
            require(games[gameIndex()].winnersExtracted, "Lottery: can't start a new lottery before the winner is extracted");

        games[gameLength].ongoing = true;
        games[gameLength].prizes = prizes;
        games[gameLength].winners = new address[](prizes.length);
        games[gameLength].rewardsRedeemed = new bool[](prizes.length);

        emit GameStarted(gameLength, prizes);

        gameLength++;
    }

    function changeChainlinkData(bytes32 keyHash, uint256 fee) external onlyDAO {
        link.keyHash = keyHash;
        link.fee = fee;
    }

    function purchaseTickets(uint256 amount) external {
        require(amount >= 10e18, "Lottery: Insufficient purchase amount");

        uint256 finalizedAmount = amount.sub(amount % 10e18);

        Game storage game = games[gameIndex()];

        require(game.ongoing, "Lottery: No ongoing game");

        dollar().transferFrom(msg.sender, treasury(), finalizedAmount);

        uint256 newTickets = finalizedAmount.div(10e18);

        Purchase memory purchase = Purchase(
            game.issuedTickets,
            game.issuedTickets.add(newTickets) - 1
        );

        game.players[msg.sender].push(game.totalPurchases);
        game.purchases[game.totalPurchases] = purchase;

        game.issuedTickets = game.issuedTickets.add(newTickets);

        emit TicketsPurchase(msg.sender, game.totalPurchases, gameIndex(), purchase.ticketStart, purchase.ticketEnd);

        game.totalPurchases += 1;
    }

    function extractWinner() external {
        Game storage game = games[gameIndex()];
        require(game.ongoing, "Lottery: winner already extracted");

        (ILotteryDao.Era era, uint256 start) = dao.era();
        require(era == ILotteryDao.Era.EXPANSION && dao.epoch() >= start + 3, "Lottery: Can only extract during expansion");

        game.ongoing = false;

        requestRandomness(link.keyHash, link.fee, uint256(keccak256(abi.encodePacked(block.number, block.difficulty, now))));

        emit LotteryEnded(gameIndex());
    }

    function redeemReward(uint256 gameIndex, uint256 purchaseIndex, uint256 winningTicket) external {
        Game storage game = games[gameIndex];

        require(game.winnersExtracted, "Lottery: winner hasn't been extracted yet");
        
        bool found;
        uint256 index;
        for (uint256 i = 0; i < game.winningTickets.length; i++) {
            if (winningTicket == game.winningTickets[i]) {
                found = true;
                index = i;
                break;
            }
        }

        require(found, "Lottery: winning ticket not found");
        require(!game.rewardsRedeemed[index], "Lottery: Reward already redeemed");

        game.rewardsRedeemed[index] = true;

        Purchase storage purchase = game.purchases[game.players[msg.sender][purchaseIndex]];

        require(purchase.ticketStart <= winningTicket && purchase.ticketEnd >= winningTicket, "Lottery: purchase doesn't contain the winning ticket");

        dao.requestDAI(msg.sender, game.prizes[index]);

        game.winners[index] = msg.sender;

        emit RewardRedeemed(msg.sender, gameIndex, game.prizes[index]);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        Game storage game = games[gameIndex()];
        
        for (uint256 i = 0; i < game.prizes.length; i++) {
            game.winningTickets.push(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randomness, game.prizes[i]))) % game.issuedTickets);
        }

        game.winnersExtracted = true;

        emit WinningTicketsSorted(gameIndex(), game.winningTickets);
    }

}