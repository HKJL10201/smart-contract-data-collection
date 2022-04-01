pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lottery
 * @dev Lottery contract allows users to enter a lottery based on fixed fee payed in Ether.
 * This is made possible by using Chainlink Oracles to get ETH/USD data feeds and true randomness
 * Chainlink Data Feed information can be found at: https://docs.chain.link/docs/using-chainlink-reference-contracts/
 */
contract Lottery is VRFConsumerBase, Ownable {
    using SafeMathChainlink for uint256;
    
    AggregatorV3Interface internal ethUsdPriceFeed;

    uint8 public usdEntryFee;
    uint256 public fee;
    bytes32 keyHash;

    address payable[] public participants;
    address public recentWinner;

    enum STATE {OPEN, DRAWING, CLOSED}
    STATE public state;

    event requestedRandomness(bytes32 _requestId);

    /**
     * @dev Used to initialuze a Lottery
     * @param _ethUsdPriceFeed Chainlink address providing the price feed
     * @param _usdEntryFee Price of entry to the lottery in USD
     * @param _vrfCoordinator VRFCoordinator contract address
     * @param _link Link contract address
     * @param _link Represents the keyHash    
     */
    constructor(address _ethUsdPriceFeed, uint8 _usdEntryFee, address _vrfCoordinator, address _link, bytes32 _keyHash)
    VRFConsumerBase(_vrfCoordinator, _link) public{
        state = STATE.CLOSED;
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        usdEntryFee = _usdEntryFee; //$
        fee =  0.1 * 10 ** 18; // 0.1 LINK
        keyHash = _keyHash;
        
    }

    /**
     * @dev Function called by a user to enter the Lottery
     */
    function enter() public payable{
        require(msg.value >= getEntranceFee(), "Sorry, not enough ETH to enter!");
        require(state == STATE.OPEN, "Sorry, entries are currently closed!");
        participants.push(msg.sender);
    }

    /**
     * @dev Returns the entrance fee in ETH
     */
    function getEntranceFee() public view returns(uint256){
        uint256 precision = 1 * 10 ** 18;
        uint256 price = getLastestEthUsdPrice();
        uint256 costToEnter = (precision / price) * (usdEntryFee * 100000000);
        return costToEnter;
    }

    /**
     * @dev Returns the latest price of ETH in USD
     */
    function getLastestEthUsdPrice() public view returns(uint256){
        (
            uint80 roundId,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ethUsdPriceFeed.latestRoundData();

        return uint256(price);
    }

    /**
     * @dev Changes the state of the lottery to: OPEN
     * Can only be called by the contract owner
     */
    function startLottery() public onlyOwner{
        require(state == STATE.CLOSED, "The lottery has already started");
        state = STATE.OPEN;
    }

    /**
     * @dev Changes the state of the lottery to: DRAWING
     * Can only be called by the contract owner
     * Function calls the pickWinner function to select a winner
     */
    function endLottery() public onlyOwner{
        require(state == STATE.OPEN, "Cannot end lottery yet!");
        state = STATE.DRAWING;
        pickWinner();
    }

    /**
     * @dev Sends a request to get a random number
     */
    function pickWinner() private returns(bytes32) {
        require(state == STATE.DRAWING, "Needs to be drawing the winner");
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit requestedRandomness(requestId);
    }

    /**
     * @dev This function is automatically called after the pickWinner function
     * A winning number is chosen and used as index in the array of participants
     * The winner is transfered all of the funds held in the contract
     * @param requestId Represents the requestId
     * @param randomness Random Integer returned  
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(randomness > 0, "Randomness number not found");
        uint winningNumber = randomness % participants.length;
        recentWinner = participants[winningNumber];
        participants = new address payable[](0);
        state = STATE.CLOSED;
        participants[winningNumber].transfer(address(this).balance);
        randomness = randomness;
    }
}