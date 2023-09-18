// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol"; //https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/VRFConsumerBase.sol

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players; //to keep the track of players
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;

    AggregatorV3Interface internal ethUsdPriceFeed; //to get the conversion rate we are using chainlink
    //We are creating a enum to know the state of lottery
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    // 0
    // 1
    //2
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;

    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress, //https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/VRFConsumerBase.sol
        address _vrfCoordinator, //https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/tests/VRFCoordinatorMock.sol
        address _link, //
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        //https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/VRFConsumerBase.sol
        usdEntryFee = 50 * (10**18); // to make it in WEI
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress); //to get the conversion rate we are using chainlink
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN); //whenever will someone enter the lottery so the state of the lottery will be open.
        //min 50$
        require(msg.value >= getEntranceFee(), "Not Enough ETH");
        players.push(msg.sender); // to keep the track of players
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; //18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cant start a new lottery yet"
        ); // if the lottery is closed
        lottery_state = LOTTERY_STATE.OPEN; // TO start the lotery
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER; //while this is happening no other functions can be called
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet"
        );

        require(_randomness > 0, "random not found");

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner]; // we got the winner
        recentWinner.transfer(address(this).balance); // to transfer all the money to the winner
        //reset lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
