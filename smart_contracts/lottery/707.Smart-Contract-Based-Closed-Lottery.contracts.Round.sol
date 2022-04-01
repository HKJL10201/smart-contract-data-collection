// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RandomNumberGenerator.sol";

contract Round is Ownable, RandomNumberGenerator {
  
    uint32 public currentRound;
    event Result(uint winningNumber, address[] winners);
    
    LotteryRound[] rounds;

    struct LotteryRound {
      mapping (uint => address[]) playersByNumber;
      mapping (address => uint) numberByPlayer;
    }

    constructor() {
        currentRound = 1;
    }

    /**
    * @dev Create new round
    */
    function _createRound() internal {
      rounds.push();
    }
  
    /**
    * @dev Get the current round
    * @return the last LotteryRound in the list
    */
    function _currentRound() view internal returns (LotteryRound storage) {
      return rounds[rounds.length - 1];
    }
    
    /**
    * @dev Get winning number, update round and return winning addresses
      @return address with winning number
    */
    function _getWinners() internal returns(address[] storage) {
        // get winning number
        uint winningNumber = _createRandomNumber(); 
        
        // get current round
        LotteryRound storage round = _currentRound();

        // update round
        currentRound++;

        // notify participants with winning number
        emit Result(winningNumber, round.playersByNumber[winningNumber]);

        // addresses with winning number
        return round.playersByNumber[winningNumber];
    }
}