// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Lottery is VRFConsumerBase, KeeperCompatibleInterface, ERC721 {
    using Counters for Counters.Counter;

    enum LotteryState {
        RUNNING,
        DRAWING,
        CLOSED
    }

    Counters.Counter private _tokenId;

    bytes32 public immutable keyHash;
    uint256 public immutable fee;

    uint256 public gameNumber;
    LotteryState public gameState;
    uint256 public lotteryPriceInWei;
    address payable[] public participants;
    uint256 public immutable gamePeriod;
    uint256 public lastTimeStamp;

    // tokenId => gameNumber => numbers merged
    mapping(uint256 => mapping(uint256 => uint256)) public lottery;
    // numbers merged => tokenId
    mapping(uint256 => uint256[]) public currentGameLottery;

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _lotteryPriceInWei,
        uint256 _gamePeriod
    )
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        ERC721("LotteryToken", "LT")
    {
        keyHash = _keyHash;
        fee = _fee;
        lotteryPriceInWei = _lotteryPriceInWei;
        gamePeriod = _gamePeriod;

        startLottery();
    }

    function startLottery() private {
        gameNumber = 1;
        gameState = LotteryState.RUNNING;
    }

    function isAscendingOrder(uint8[6] memory numbers)
        public
        pure
        returns (bool)
    {
        return (numbers[0] < numbers[1] &&
            numbers[1] < numbers[2] &&
            numbers[2] < numbers[3] &&
            numbers[3] < numbers[4] &&
            numbers[4] < numbers[5]);
    }

    function buyLottery(uint8[6] memory numbers) public payable {
        require(gameState == LotteryState.RUNNING);
        require(
            isAscendingOrder(numbers),
            "Numbers should be in ascending order!"
        );
        require(msg.value >= fee, "Not enough ETH!");

        issueLotteryToken(msg.sender, mergeNumbers(numbers));
    }

    function mergeNumbers(uint8[6] memory numbers)
        internal
        pure
        returns (uint256)
    {
        uint256 merged = 0;
        for (uint8 i = 0; i < 6; i++) {
            merged |= numbers[i];
            merged <<= 8;
        }
        return merged >> 8;
    }

    function issueLotteryToken(address to, uint256 numbersMerged) internal {
        _tokenId.increment();

        uint256 newTokenId = _tokenId.current();
        _safeMint(to, newTokenId);

        lottery[newTokenId][gameNumber] = numbersMerged;
        currentGameLottery[numbersMerged].push(newTokenId);
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(
        bytes32, /* requestId */
        uint256 randomness
    ) internal override {
        uint8[6] memory game_reuslt = extractNumbers(randomness);
        uint256[] memory winnerLotteries = currentGameLottery[
            mergeNumbers(game_reuslt)
        ];
        uint256 winningPrice = address(this).balance / winnerLotteries.length;

        for (uint256 i = 0; i < winnerLotteries.length; i++) {
            address payable winner = payable(ownerOf(winnerLotteries[i]));
            winner.transfer(winningPrice);
        }

        gameState = LotteryState.RUNNING;
    }

    function extractNumbers(uint256 source)
        internal
        pure
        returns (uint8[6] memory)
    {
        uint8[6] memory numbers;

        for (uint8 i = 0; i < 5; i++) {
            numbers[i] = uint8((source % 256) % 45) + 1;
            source >>= 8;
        }
        numbers[5] = uint8((source % 256) % 45) + 1; // Power ball

        return numbers;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > gamePeriod;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /*performData*/
    ) external override {
        lastTimeStamp = block.timestamp;
        gameNumber += 1;
        gameState = LotteryState.DRAWING;
        getRandomNumber();
    }
}
