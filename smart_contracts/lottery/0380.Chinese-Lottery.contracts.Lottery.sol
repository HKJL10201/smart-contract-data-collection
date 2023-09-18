//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import "github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract Lottery is VRFConsumerBaseV2 {
    enum LOTTERY_STATE { OPEN, CLOSED, SELECTING_WINNER}
    LOTTERY_STATE private lottery_state; 
    address payable[] public players;
    address public manager;
    address payable winner;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    //this is rinkeby LINK contract
    // address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    uint32 callbackGasLimit = 1000000;

    uint16 requestConfirmations = 5;
    uint32 numWords = 2;

    // uint256[] public s_randomWords;
    uint256 public s_randomWords;
    uint256 internal s_requestId;

    event setupRandomNumber(uint[] randomWord, uint settleds_randomWords);

    constructor(address vrfCoordinator, bytes32 _keyhash) VRFConsumerBaseV2(vrfCoordinator) {
        // setPublicChainlinkToken();
        keyHash = _keyhash;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        manager = msg.sender;
        // s_subscriptionId = subscriptionId;
        lottery_state = LOTTERY_STATE.CLOSED;
    }

//     constructor(address vrfCoordinator, address link, bytes32 _keyhash, uint256 _fee)
// VRFConsumerBase(vrfCoordinator, link)
// {
//    keyHash = _keyhash;
//    fee = _fee;
//    admin = msg.sender;
// }

    receive() external payable isOpen {
        require(msg.value == 0.001 ether, "Only transfer 0.001");
        players.push(payable(msg.sender));
    }

    function getBalance() public view onlyWinnerAndOwner returns (uint256) {
        return address(this).balance;
    }

    function chooseWinner()
        public
        onlyOwner
        isSelectingWinner
        playerExist
        returns (address)
    {
        lottery_state = LOTTERY_STATE.CLOSED;

        winner = players[s_randomWords];
        // winner = players[randomNumber % 37];
        winner.transfer(getBalance());
        return winner;
    }

    function startNewBid() public onlyOwner isClosed {
        // re set variables
        lottery_state = LOTTERY_STATE.OPEN;
        winner = payable(address(0));
        players = new address payable[](0);
        s_requestId = 0;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner playerExist isOpen {
        lottery_state = LOTTERY_STATE.SELECTING_WINNER;
        // require(s_requestId == 0, "already request randomWords");
        // locked = true;
        // Will revert if subscription is not set and funded.
        // check if theres any player in the bid, so fulfillRandomWords wont revert
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override isSelectingWinner {
        s_randomWords = (randomWords[0] % players.length);
        // s_randomWords = randomWords ;
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only Owner Can Access");
        _;
    }

    modifier onlyWinnerAndOwner() {
        require(msg.sender == manager || msg.sender == winner, "Only Owner and Current Winner can access");
        _;
    }

    modifier isOpen() {
        require(lottery_state == LOTTERY_STATE.OPEN, "Bet is not open");
        _;
    }

    modifier isClosed() {
        require(lottery_state == LOTTERY_STATE.CLOSED, "Bet is not closed yet");
        _;
    }

    modifier isSelectingWinner() {
      require(lottery_state == LOTTERY_STATE.SELECTING_WINNER, "Bet isn't selecting winner yet");
      _;
  }

    modifier playerExist() {
        require(players.length > 0, "No Players");
        _;
    }
}
