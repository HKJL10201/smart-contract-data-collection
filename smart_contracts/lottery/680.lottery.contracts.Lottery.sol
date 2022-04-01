// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;

    AggregatorV3Interface internal ethUSDPriceFeed;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    // VRF is for getting random number from chainlink
    // our contract inherits from VRFconsumable base,
    // which has a constructor that needs VRF Coordinator address and link token address
    // _vrfCoordinator is an onchain contract checks that the number is random
    // link token address is where we pay for using the services
    // _keyhash uniquely identifies the node we're going to use
    // _fee is the amount we pay
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress); // get eth_usd price feed
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee; //
        keyhash = _keyhash; //
    }

    function enter() public payable {
        // $50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough eth!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDPriceFeed.latestRoundData();
        uint256 adjusted_price = uint256(price) * 10**10; // 18 dec
        // 50/2000
        // 50 * 100000 / 2000 since cannot 50/2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjusted_price;
        return costToEnter; // in eth
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );

        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // requestRandomness is inherited functoin from VRFConsumableBase.sol
        // Can read the VRFConsumableBase.sol code to see that it takes a keyhash and a fee, and returns a bytes32 requestId
        // these are parameterized so that it's entered when the contract is constructed
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    // Callback function is called by VRF Coordinator when done
    // we only want our chainlink node to call this, hence internal
    // keyword override because we're overriding the original function
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You are not there yet!"
        );
        require(_randomness > 0, "random not found");
        // pick a random winner from the players array
        // modding; dividing by a number will always return a remainder of 0 to (number-1).
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        // reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness; // to keep track of the random number
    }
}
