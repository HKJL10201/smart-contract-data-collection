pragma solidity ^0.5.8;

import { SafeMath } from "./SafeMath.sol";

contract Lottery {

    //Rounds of lottery
    enum LotteryState { FirstRound, SecondRound, Finished }

    mapping (uint8 => address payable[]) playersByNumber;
    mapping (address => bytes32) playersHash;

    uint8 winningNumber;
    uint8[] numbers;
    uint8 players;
    address owner;
    LotteryState state;

    //Constructor
    constructor () public {
        owner = msg.sender;
        state = LotteryState.FirstRound;
    }

    event SecondRound(uint8 numberOfPlayers);
    event DetermineWinner(uint8 winningNumber, address payable[] winners);

    //Owner only modifier
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can do this.");
        _;
    }

    //Checks if the given address is the owner
    function isOwner() public view returns (bool) {
        return (msg.sender == owner);
    }

    //Get current state
    function getRound() public view returns (LotteryState) {
        return state;
    }

    //Enter hash of guessed number
    function enterHash(bytes32 x) public payable {
        require(state == LotteryState.FirstRound, "Must be first round");
        require(msg.value == 1 ether, "Must be 1 Eth");
        playersHash[msg.sender] = x;
        players += 1;
    }

    //Owner runs the second round of the lottery
    function runSecondRound() public onlyOwner {
        require(state == LotteryState.FirstRound, "Must be first round");
        emit SecondRound(players);
        state = LotteryState.SecondRound;
    }

    //Participants enter their original numbers
    function enterNumber(uint8 number) public {
        require(number<=250, "1-250 only");
        require(state == LotteryState.SecondRound, "Must be second round");
        require(keccak256(abi.encodePacked(number, msg.sender)) == playersHash[msg.sender], "Number must be same as chosen");
        playersByNumber[number].push(msg.sender);
        numbers.push(number);
    }

    //Owner determines winner
    function determineWinner() public onlyOwner{
        state = LotteryState.Finished;
        winningNumber = random();
        address payable[] memory winners = playersByNumber[winningNumber];
        emit DetermineWinner(winningNumber, winners);
        if (winners.length > 0) {
            uint256 prizeAmount = SafeMath.div(address(this).balance, winners.length);
            for (uint8 i = 0; i < winners.length; i++) {
                address payable winner = winners[i];
                winner.transfer(prizeAmount);
            }
        }
    }

    //Gets the winners
    function getWinners() public view returns (address payable[] memory) {
        require(state == LotteryState.Finished, "LotteryState needs to be finished");
        return playersByNumber[winningNumber];
    }

    //Randomise the winning number by XOR
    function random() private view returns (uint8) {
        uint8 randomNumber = numbers[0];
        for (uint8 i = 1; i < numbers.length; ++i) {
            randomNumber ^= numbers[i];
        }
        return randomNumber;
    }
}