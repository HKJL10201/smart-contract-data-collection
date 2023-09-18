// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Round.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery is Ownable, Round {

    using SafeMath for uint256;

    uint private _bettingAmount;
    uint8 private _minNumber;
    uint16 private _maxNumber;

    enum LotteryState { Open, Closed }
    LotteryState state;

    mapping (address => bool) internal _participants;

    constructor() {
        state = LotteryState.Closed;
        _minNumber = 1;
        _maxNumber = 1000;
        _bettingAmount = 0.1 ether;
    }

    /**
    * @dev Add player with chosen number for current round
    * @param number between 1 and 1000
    */
    function guess(uint16 number) public payable validateGuess(msg.value, number, msg.sender) lotteryStatus {
        // get current round
        LotteryRound storage round = _currentRound();

        // check if player has already entered for current round
        require(round.numberByPlayer[msg.sender] == 0, "You have already participated");

        // add participant with chosen number
        round.numberByPlayer[msg.sender] = number;
        round.playersByNumber[number].push(msg.sender);
    }

    /**
    * @dev Pick the winner and transfer money to winning addresses
    * @notice call this function to determine the winner(s)
    */
    function pickWinner() public onlyOwner lotteryStatus {
        address[] storage winningPlayers = _getWinners();

        if (winningPlayers.length > 0) {
            // divide pot over winners
            uint balanceToDistribute = address(this).balance.div(winningPlayers.length);

            // tranfer winning amount to each winner
            for (uint i = 0; i < winningPlayers.length; i++) {
                payable(winningPlayers[i]).transfer(balanceToDistribute);
            }    
        }

        closeLottery();
    }

    /**
    * @dev Get balance of contract
    * @notice This will return the total value of the lottery pot
    * @return balance of contract
    */
    function getPot() public view returns (uint) {
        return address(this).balance;
    }

    /**
    * @dev Change betting amount
    * @param amountOfEther is the betting amount in Ether
    */
    function setBettingAmount(uint amountOfEther) public onlyOwner {
        _bettingAmount = amountOfEther;
    }

    /**
    * @dev Change min and max picking number
    * @param min number and max number for picking range
    */
    function setNumberRange(uint8 min, uint16 max) public onlyOwner {
        _minNumber = min;
        _maxNumber = max;
    }

    /**
    * @dev Open lottery
    */
    function openLottery() public onlyOwner {
        require(state == LotteryState.Closed, "Lottery is already open");
        state = LotteryState.Open;
        _createRound();
    }

    /**
    * @dev Close lottery
    */
    function closeLottery() public onlyOwner {
        require(state == LotteryState.Open, "Lottery is already closed");
        state = LotteryState.Closed;
    }
    
    /**
    * @dev Add participant
      @param participant that is being added
    */
    function addParticipants(address participant) public onlyOwner {
        require(!_participants[participant], "Participant already added");
        _participants[participant] = true;
    }

    /**
    * @dev Remove participant by address
      @param participant address
    */
    function removeParticipant(address participant) public onlyOwner {
      require(_participants[participant], "Participant does not exist");
      _participants[participant] = false;
    }

    /**
    * @dev Throws if: 
        1) Amount is not equal to 0.1 Ether
        2) Chosen number is not between 1 and 1000
        3) Participant is owner
        4) Participant is not whitelisted
    * @param amount of ether, chosen number and address of sender
    */
    modifier validateGuess(uint amount, uint16 chosenNumber, address sender) {
        require(amount == _bettingAmount, "Must exactly be 0.1 Ether");
        require(chosenNumber >= _minNumber && chosenNumber <= _maxNumber, "Enter a number between 1 and 1000");
        require(sender != owner(), "Owners cannot participate");
        require(_participants[sender], "You are not whitelisted");
        _;
    }

    /**
    * @dev Throws if lottery status is closed
    */
    modifier lotteryStatus() {
        require(state == LotteryState.Open, "Currently the lottery is closed");
        _;
    }
}