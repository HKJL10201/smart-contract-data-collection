pragma solidity ^0.6.5;

import "https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/ChainlinkClient.sol";
import {RandomnessInterface} from "./RandomnessInterface.sol";

contract Lottery is ChainlinkClient {
    constructor(address _randomContractAddress) public {
        setPublicChainlinkToken();
        randomContractAddress = _randomContractAddress;
        contractCreator = msg.sender;
        oneTime = false;
    }

    /*Open means user can participate in current lottery round, 
    closed means current lottery round is over and winner is being picked*/
    enum lotteryStates {Open, Closed}
    lotteryStates currentLotteryState;
    address public contractCreator;
    address randomContractAddress;
    address oracleAlarmAddress = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
    bytes32 oracleJobId = "a7ab70d561d34eb49e9b1612fd2e044b";
    uint256 oraclePayment = 0.1 * 10**18; //0.1 LINK
    uint256 winnerIndex;
    address payable[] public participants;
    bool oneTime;
    event PlayerEntered(uint256 balance, uint256 totalPlayers);
    event WinnerAnnounced(address winner);
    event NewRound();

    //Can only be called once
    function triggerLottery() public {
        assert(oneTime == false);
        require(msg.sender == contractCreator, "Access Denied!");
        currentLotteryState = lotteryStates.Open;
        oneTime = true;
        startLottery();
    }

    receive() external payable {
        enterLottery();
    }

    function startLottery() private {
        Chainlink.Request memory req =
            buildChainlinkRequest(
                oracleJobId,
                address(this),
                this.fulfill_alarm.selector
            );
        req.addUint("until", now + 1 days);
        sendChainlinkRequestTo(oracleAlarmAddress, req, oraclePayment);
    }

    function fulfill_alarm(bytes32 _requestId)
        public
        recordChainlinkFulfillment(_requestId)
    {
        require(msg.sender == oracleAlarmAddress, "Access Denied!");
        //If anyone has participated then proceed to pick the winner
        if (participants.length > 0) {
            //Lottery has been closed for the time being
            currentLotteryState = lotteryStates.Closed;
            RandomnessInterface(randomContractAddress).getRandomNumber();
        }
        //if no one has participated in the current lottery round then no need to find the winner, so starting new lottery round
        else {
            startLottery();
        }
    }

    function finalizeRound(uint256 _randomNumber) external {
        require(msg.sender == randomContractAddress, "Access Denied!");
        assert(currentLotteryState == lotteryStates.Closed);
        require(_randomNumber > 0, "Couldn't find random number!");
        winnerIndex = _randomNumber % participants.length;
        participants[winnerIndex].transfer(address(this).balance);
        
        //to let our front-end know who has won the lottery
        emit WinnerAnnounced(participants[winnerIndex]);
        
        participants = new address payable[](0);
        
        //to let our front-end know that new round of lottery has been started
        emit NewRound();

        //Since winner is decided therefore opening lottery
        currentLotteryState = lotteryStates.Open;

        //Starting new lottery round
        startLottery();
    }

    function enterLottery() public payable {
        require(
            currentLotteryState == lotteryStates.Open,
            "Lottery round is in process. Try again after sometime!"
        );
        require(
            msg.value >= 0.01 ether,
            "Minimum deposit should be 0.01 ether"
        );
        participants.push(msg.sender);
        
        //so that our front-end can update participants and total pot
        emit PlayerEntered(address(this).balance, participants.length);
    }

    function getParticipants() public view returns (uint256) {
        return participants.length;
    }
}
