// SPDX-License-Identifier: MIT

// Smart contract that lets anyone deposit ETH into the contract
// Only the owner of the contract can withdraw the ETH
pragma solidity ^0.6.6;

// Get the latest ETH/USD price from chainlink price feed

// IMPORTANT: This contract has been updated to use the Goerli testnet
// Please see: https://docs.chain.link/docs/get-the-latest-price/
// For more information

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


contract Lottery is VRFConsumerBase , Ownable{
    using SafeMathChainlink for uint256;
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed; 
    enum LOTTERY_STATE{
        OPEN, CLOSED, CALCULATED_WINNER
    }

    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;

    constructor(
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link,
        uint256 _fee,
        bytes32 _keyhash) 
    public VRFConsumerBase(_vrfCoordinator, _link) 
    {
        //https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd
        //0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state=LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;

    }

    function enter() public payable {
        require(lottery_state==LOTTERY_STATE.OPEN);
        require(msg.value>=getEntranceFee(), "Not enough fee");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns(uint256) 
    {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**18; // 18 decimal

        uint256 costToEnter = (usdEntryFee * 10**18)/adjustedPrice;
        return costToEnter;
        
    }
    function startLottery() public  onlyOwner{
        require(lottery_state==LOTTERY_STATE.CLOSED, "Can't star an new lottery");
        lottery_state=LOTTERY_STATE.OPEN;
    }
    function endLottery() public onlyOwner{
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce,
        //             msg.sender,
        //             block.difficulty,
        //             block.timestamp
        //         )
        //     )
        // ) % players.length;
        lottery_state=LOTTERY_STATE.CALCULATED_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        require (
            lottery_state==LOTTERY_STATE.CALCULATED_WINNER, 
            "You aren't there yet!"
            );
        require(_randomness>0, "random-not-found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        //Randomness
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness=_randomness;
    }
}