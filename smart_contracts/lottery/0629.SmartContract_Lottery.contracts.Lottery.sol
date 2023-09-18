//SPDX-License-Identifier:MIT

pragma solidity  >=0.6.0 <0.8.0;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
contract Lottery is VRFConsumerBase , Ownable{
    address payable[]  public players;
    address payable public winner;
    uint256 public usdEntryFee;
    uint256 public fee;
    bytes32 public keyHash;
    uint256 public randomness;
    uint256 public indexOfSelectedWinner;
    AggregatorV3Interface internal ethUSDPriceFeed;
    enum Lottery_State{
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    Lottery_State public lottery_state;
    event RequestedRandomness(bytes32 requestId);
    constructor(uint256 _usdEntryFee
    ,address _priceFeedAddress
    , address _vrfCoordinator
    , address _link
    , uint256 _fee
    ,bytes32 _keyhash) 
    public VRFConsumerBase(_vrfCoordinator,_link)
    {
        usdEntryFee = _usdEntryFee * (10**18);
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = Lottery_State.CLOSED;
        fee = _fee;
        keyHash=_keyhash;
    }
    function enter() public payable{
        require(lottery_state == Lottery_State.OPEN);
        require(msg.value >= getEntranceFee(),"Not enough ETH!");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256){
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethUSDPriceFeed.latestRoundData();
        uint256 adjustedPrice = (uint256)(price * 10 ** 10);
        //$50, $2000 / ETH
        //50/2000
        //50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**10)/adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner{
        require(lottery_state==Lottery_State.CLOSED,"Can't start a new lottery yet!");
        lottery_state = Lottery_State.OPEN;
    }

    function endLottery() public{
        /*uin256(keccak256(abi.encodePacked(
            nonce,
            msg.sender,
            block.difficulty,
            block.timestamp
        );))%players.length;*/
        lottery_state = Lottery_State.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyHash,fee);
        emit RequestedRandomness(requestID);
    }

    function fulfillRandomness(bytes32 requestID, uint256 randomness) internal override
    {
        require(lottery_state == Lottery_State.CALCULATING_WINNER,"You aren't there yet!");
        require(randomness > 0,"random-not-found");
        indexOfSelectedWinner = randomness % players.length;
        winner = players[indexOfSelectedWinner];
        winner.transfer(address(this).balance);
        //Reset
        players = new address payable[](0);
        lottery_state = Lottery_State.CLOSED;
        randomness = randomness;
    }

}



