//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; //for v2

/*This contract when deployed can start the lottery,
make users enter based on the minimum fee specified in
the getEntrance() fx, and the contracts owner can end 
the lottery and the winner is to be selected based on the 
chainlink vrf randomness
*/

contract Lottery is Ownable, VRFConsumerBaseV2 {
    //vrf v2 parameters
    uint64 s_subscriptionId;
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 keyhash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2; //vrf v2 feature choosing the number of randomn words to receive
    address payable[] public players; //players array
    uint256 minimumFeeUsd; //minimum entry fee to the lottery
    AggregatorV3Interface aggregator; // aggregator object of the interface
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state; //keeps track of lottery state
    uint256 public recent_randomness; //recent randomn number obtained
    uint256 fee; //vrfv1 fee feature
    address payable public recent_winner; // recent winner address

    event request_id(uint256 requestId);

    //constructor parameters for vrf, aggregator and linktoken, //uint256 _fee,
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint64 sId
    ) public VRFConsumerBaseV2(_vrfCoordinator) {
        lottery_state = LOTTERY_STATE.CLOSED;
        minimumFeeUsd = 50 * 10**18;
        aggregator = AggregatorV3Interface(_priceFeedAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyhash = _keyHash;
        s_subscriptionId = sId;
        //fee = _fee;
    }

    function enter() public payable {
        //lottery state must be open for one to enter
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Sorry the lottery aint open yet!"
        );
        // you must enter with more than the entrance fee which is 50 usd in eth
        require(msg.value >= getEntranceFee());
        players.push(payable(msg.sender));
    }

    //the entrance fee in usd fetched from aggregator price of eth which converts minimumaFeeUsd which is 50 usd to eth
    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = aggregator.latestRoundData();
        uint256 adjustedPrice = uint256(price * 10**10);
        return (minimumFeeUsd * 10**18) / adjustedPrice;
    }

    function startLottery() public onlyOwner {
        //to start alottery only the owner can do that and it has to be closed ie the owner cant open a new lottery while theres an existing opened lottery
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Sorry, You cant start a new lottery yet!"
        );
        // then the lottery opens
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner returns (uint256) {
        require(
            // onlyowner can end the lottery and it has to be open ie the owner cant end the lottery while no lottery is started
            lottery_state == LOTTERY_STATE.OPEN,
            "You cant end lottery, none has started yet!"
        );
        //then clottery state becomes calculating winner
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        //v2 fx for requesting randomness only when the subscrption id is funded
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyhash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        ); //v2
        //bytes32 requestId = requestRandomness(keyhash, fee);
        emit request_id(requestId); //request id
        return requestId;
    }

    //overrriding the fulfiill fx called by the coordinator to obtai randomness
    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] memory randomness
    ) internal override {
        require(
            // this fx only operates when the lottery state is calculatingwinner
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aint there yet!"
        );
        //require the random word to be greater than zero
        //require(randomness[0] > 0, "randomn not found!");
        //choosing the first word in the array of randomwords
        uint256[] memory randomWords = randomness;
        recent_randomness = randomWords[1];
        //getting the winner using remainder theory
        uint256 index_of_winner = recent_randomness % players.length;
        //making the address of the winner payable
        recent_winner = players[index_of_winner];
        //sending this contract balance to the winner
        recent_winner.transfer(address(this).balance - 890000000);
        //initializing the players array
        players = new address payable[](0);
        //closing the lottery afterwards
        lottery_state = LOTTERY_STATE.CLOSED;
    }
}
