pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntryFee;
    uint256 private randNonce = 0;
    AggregatorV3Interface internal ethUsdPrice;

    // enum is a easier friendly way to represent ints, here: 0, 1, 2
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    constructor(address _priceFeed) public {
        usdEntryFee = 50 * (10**18);
        ethUsdPrice = AggregatorV3Interface(_priceFeed);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

    function enter() public payable {
        // $50 minimum
        //lottery_state = LOTTERY_STATE.OPEN;
        require(lottery_state == LOTTERY_STATE.OPEN, "Needs to be open first");
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        //
        (, int256 price, , , ) = ethUsdPrice.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals now
        // $usd50 is entrance fee, price will be eth price in $usd
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return uint256(costToEnter);
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Cannot start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        // not a method to use in mainnet chain, not safe
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Lottery needs to be open first"
        );
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        uint256 randomNum = uint256(
            keccak256(
                (
                    abi.encodePacked(
                        randNonce,
                        msg.sender,
                        block.difficulty,
                        block.timestamp
                    )
                )
            )
        );
        randNonce++;
        uint256 indexOfWinner = randomNum % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        players = new address payable[](0);
    }
}
