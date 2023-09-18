// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
contract Lottery is VRFConsumerBaseV2 {
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint public randomResult;
    bytes32 private immutable i_gasLane; // identifies which Chainlink oracle to use
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFORMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    constructor(address vrfCoordinatorV2, bytes32 gasLane,uint64 subscriptionId,uint32 callbackGasLimit)
        VRFConsumerBaseV2( vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane; //keyhash
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        owner = msg.sender;
        lotteryId = 1;
        }

    function getRandomNumber() internal {
   uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane, //keyhash
      i_subscriptionId,
      REQUEST_CONFORMATION,
      i_callbackGasLimit,
      NUM_WORDS
    );
    randomResult = requestId;
    payWinner();
    }

    function fulfillRandomWords( uint256 /* requestId */,  uint256[] memory _randomWords) internal override{
         randomResult = _randomWords[0];
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

 function reentry() private view returns(bool){
        for(uint i=0 ; i<players.length ; i++) {
            if(players[i] == msg.sender){
                return true;
            }
        }
             return false;
    }
    function enter() public payable {
        require(!reentry(),"You are already registered in this lottery");
        require(msg.value > .01 ether,"Entry Fees is not valid");

        // address of player entering lottery
        players.push(payable(msg.sender));
    }

    function pickWinner() public onlyowner {
        getRandomNumber();
    }

    function payWinner() public {
        uint index = randomResult % players.length;
        players[index].transfer(address(this).balance);

        lotteryHistory[lotteryId] = players[index];
        lotteryId++;
        
        // reset the state of the contract
        players = new address payable[](0);
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}
