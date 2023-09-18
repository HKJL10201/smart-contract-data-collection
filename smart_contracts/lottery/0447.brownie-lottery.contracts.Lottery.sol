// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable[] public winner_players;
    uint256 public number_of_players;
    uint256 public number_of_winners;
    address payable public recent_winner;

    uint256 public randomness;
    bytes32 public requestId;
    mapping(bytes32 => uint256) public Randomness;

    uint256 public usdEntryFee;
    AggregatorV3Interface internal priceFeed;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING
    }
    LOTTERY_STATE public lottery_state;

    uint256 public fee;
    bytes32 public keyhash;

    event RequestedRandomness(bytes32 requestId);
    event LogWinnerPlayer(address winnerPlayer);

    constructor(
        address _priceFeedAddress,
        address _link,
        address _vrfCoordinator,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        usdEntryFee = 10 * 10**18;
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        uint256 minimumUSD = getEntranceFee();
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "The lottery is not open."
        );
        require(msg.value >= minimumUSD, "Not enough ETH!");
        players.push(payable(msg.sender));
        number_of_players++;
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10;
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery(uint256 _number_of_winners) public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "There is no lottery yet!"
        );
        number_of_winners = _number_of_winners;
        lottery_state = LOTTERY_STATE.CALCULATING;
        require(number_of_players >= 0, "There are no players in the lottery!");
        for (uint256 i = 0; i < number_of_winners; i++) {
            getRandomNumber();
        }
    }

    function getRandomNumber() internal returns (uint256) {
        requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
        require(
            lottery_state == LOTTERY_STATE.CALCULATING,
            "You aren't there yet!"
        );
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        randomness = _randomness;
        require(randomness > 0, "Random not found!");
        requestId = _requestId;
        Randomness[requestId] = randomness;
        drawWinner();
    }

    function drawWinner() internal {
        uint256 random_number = randomness % players.length;
        recent_winner = players[random_number];
        winner_players.push(payable(recent_winner));
        emit LogWinnerPlayer(recent_winner);
        removeIndex(random_number);
    }

    function removeIndex(uint256 random_number) internal {
        random_number = random_number;
        delete players[random_number];
        players[random_number] = players[players.length - 1];
        players.pop();
    }

    function payWinners() internal {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING,
            "You aren't there yet!"
        );
        uint256 amount_per_winner = address(this).balance / number_of_winners;
        for (uint256 i; i < winner_players.length; i++) {
            winner_players[i].transfer(amount_per_winner);
        }
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function getWinnerPlayers(uint256 index)
        public
        view
        returns (address player)
    {
        return winner_players[index];
    }
}
