pragma solidity ^0.6.0;
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "./interfaces/RandomnessInterface.sol";
import "./interfaces/GovernanceInterface.sol";
import "hardhat/console.sol";

contract Lottery is ChainlinkClient {
    enum LOTTERY_STATE { OPEN, CLOSED, CALCULATING_WINNER }
    LOTTERY_STATE public lottery_state;
    address payable[] public players;
    uint256 public lotteryId;
    uint256 public price;
    GovernanceInterface private governance;

    mapping(uint => uint) public lottery_duration;

    event AnnounceWinner(address winner);

    constructor(uint256 _price, address _governance) public {
        setPublicChainlinkToken();
        price = _price;
        lotteryId = 1;
        lottery_state = LOTTERY_STATE.CLOSED;

        //Governance Init
        governance = GovernanceInterface(_governance);
        governance.initLottery(address(this));
    }

    //Starting Oracle Alarm
    function start_new_lottery(uint256 duration) public {
        require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN;
        lottery_duration[lotteryId] = block.timestamp + duration;
    }

    //Callback Function after Oracle Alarm is Fulfilled
    function fulfill_alarm() external {
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery hasn't even started!");
        require(lottery_duration[lotteryId] <= block.timestamp, "The Lottery has not ended yet");
        lotteryId = lotteryId + 1;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        pickWinner();
    }

    //User joins lottery
    function enter() public payable {
        assert(msg.value == price);
        assert(lottery_state == LOTTERY_STATE.OPEN);
        players.push(msg.sender);
    }

    //Picking Winner
    function pickWinner() internal {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet");
        RandomnessInterface(governance.randomness()).getRandomNumber(lotteryId);
    }
    
    //Get Winner through generated random number
    function fulfill_random(uint256 randomness) external {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        require(randomness > 0, "random-not-found");
        uint256 index = randomness % players.length;
        players[index].transfer(address(this).balance);

        emit AnnounceWinner(address(players[index]));

        //Reset Lottery
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
    }

} 
