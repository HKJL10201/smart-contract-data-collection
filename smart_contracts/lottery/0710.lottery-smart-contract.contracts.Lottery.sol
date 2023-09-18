// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable{

    using SafeMathChainlink for uint256;

    // keep a record of all addresses who entered the lottery
    address payable[] public participants;
    address payable public winner;
    uint256 public usdEntryFee;
    uint256 public randomness;
    AggregatorV3Interface internal ethUSDPriceFeed;
    uint256 public fee;
    bytes32 public keyhash;
    enum LOTTERY_STATE {
        OPEN,
        CLOSE,
        CALCULATING_WINNER
    }

    LOTTERY_STATE public lotteryState;

    event RandomeEmitter(bytes32 indexed requestId);

    constructor (uint256 _entryFee, address _priceFeedAddress, address _vrfCoordinatorAddress, address _linkAddress, uint256 _chainFee, bytes32 _keyhash) public VRFConsumerBase(_vrfCoordinatorAddress, _linkAddress){
        usdEntryFee = _entryFee * (10 ** 18);
        fee = _chainFee;
        keyhash = _keyhash;
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lotteryState = LOTTERY_STATE.CLOSE;

    }

    // function to start a lottery
    function startLottery() public onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSE, "Cant start a new lottery");

        lotteryState = LOTTERY_STATE.OPEN;
    }

    function setMinimumEntry(uint256 _fee) public {
        usdEntryFee = _fee;
    }

    // function to enter into a lottery
    function enter() public payable{
        // check if lottery open for entry
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open for emtry");
        // keep a list of all participant addresses
        // msg.sender gives the address of the participant
        require(msg.value >= getEntranceFee(), "Entry fee not sufficient");
        participants.push(msg.sender);
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = ethUSDPriceFeed.latestRoundData();
          uint256 adjustedPrice = uint256(price) * 10 ** 10; 
          return adjustedPrice;
    }

    // function to get the entrance fee
    function getEntranceFee() public view returns (uint256) {
        (,int256 price, , , ) = ethUSDPriceFeed.latestRoundData();

        uint256 adjustedPrice = uint256(price) * 10 ** 10; // 18 decimals

        // we are multiplying again by 10^18 to cancel out the units in price
        // ultimately cost to enter is also in wei (10^18) decimals
        
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice;
        return costToEnter;

    }   

    // function to stop lottery intake
    // only admin can do this
    function stopLottery() public onlyOwner{
        require(lotteryState == LOTTERY_STATE.OPEN, "No open lottery");
        selectWinner();
    }

    // function to select a winner at random
    // transfers funds once winnder is selected
    // resets lottery - removes all participants and stops the lottery
    function selectWinner() internal {
        lotteryState = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RandomeEmitter(requestId);

    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) 
    internal 
    override 
    { 
        require(lotteryState == LOTTERY_STATE.CALCULATING_WINNER, "Still not there yet");
        require(_randomness>0, "random not found");
        randomness = _randomness;
        uint256 winnerIndex = _randomness % participants.length;
        winner = participants[winnerIndex]; 
        transferWinnerFunds();    
        resetLottery();
    }

    // function to transfer all funds to the winner
    function transferWinnerFunds() internal  {
        //address(this) gives us the current lottery smart contract address
        // transfer is again a native functino inside address that transfers
        // a specific amount from current contract address to a specific external address
        winner.transfer(address(this).balance);
    }

    function resetLottery() internal {
        // reset all participants back to zero and reset lottery state to close
        participants = new address payable [](0);
        lotteryState = LOTTERY_STATE.CLOSE;
    }
}