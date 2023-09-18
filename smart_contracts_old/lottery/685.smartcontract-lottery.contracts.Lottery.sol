//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//this has onlyOwner function and you make contract ownable
import "@openzeppelin/contracts/access/Ownable.sol";
//this is for the random number
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // address payable array of lottery players
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    // need a price feed to get $50 in ETH
    AggregatorV3Interface internal ethUsdPriceFeed;
    // enum is a good way to represent the different states of the Lottery
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        // the lottery should be closed when contract is first deployed
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    //function to enter the lottery. since this involves giving money to contract you need to make it payable.
    function enter() public payable {
        //$50 minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        //how to get price from price feed
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        //typecast price to uint and time 10^10 bc we know it has 8 decimals and we wanna work w 18
        uint256 adjustedPrice = uint256(price) * 10**10;
        // $50, $2,000 /ETH
        // 50/2000 but solidity doesnt like decimals so
        // 50 * big number / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        //this is a quick way to get psuedorandom numbers but DO NOT USE THIS IN PRODUCTION
        //bc this way can be rigged by
        // uint256(
        //     keccack256(
        //         abi.encodePAcked(
        //             nonce, //predictable
        //             msg.sender, //predictable
        //             block.difficulty, // can be manipulated by miners
        //             block.timestamp // predictable
        //         )
        //     )
        // ) % players.length;

        //in this first transaction we are going to end the lottery and request a random number from oracle
        //this once the chainlink node creates a random number its gonna call a second transation itself
        //called fulfill randomness
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    //only want chainlink node to be able to call this function so we use internal bc vrf coordinator calls it
    //override means we are overriding the original declaration or fulfillRandomness
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        //modulo is a good way to select a random winner
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        //transfer all of the money from this address to the winner
        recentWinner.transfer(address(this).balance);
        //Reset lottery
        //Reset players to be a brand new array
        players = new address payable[](0);
        //reset lottery state to closed
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
