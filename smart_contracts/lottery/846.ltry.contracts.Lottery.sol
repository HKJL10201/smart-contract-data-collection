pragma solidity ^0.4.11;


import "./LotteryToken.sol";


// Cryptolot lottery decentralized application
//
contract Lottery {
  // Event participant with entry address and the number of lottery entry tokens
  //
  // @param entryAddress Participant wallet address
  // @param tokens Participant submitted tokens
  //
  struct Participant {
    address entryAddress;
    uint256 tokens;
  }


  // Event data structure containing the 3 weekly winners and the total
  // prize pool token supply
  //
  // @param participants Ordered list of participants
  // @param participantsLength Total number of participants
  // @param startTime Event start date
  // @param endTime Event end date
  // @param prizePoolSupply Total prize pool when the event ended
  //
  struct Event {
    mapping (uint => Participant) participants;
    uint participantsLength;
    uint startTime;
    uint endTime;
    uint256 prizePoolSupply;
  }


  // Envent configuration parameter, past events and their winners. The last
  // event added is the ongoing one.
  //
  mapping (uint => Event) public events;
  uint currentEvent;

  uint public eventDuration = 7 * 1 days;
  uint public eventWinnerCount = 3;



  // Prize pool address, public, for everyone to see and send coins to.
  //
  address public prizePool;


  // Setup the lottery and initialize prize pool address
  //
  function Lottery(address _prizePool) {
    prizePool = _prizePool;
  }


  // Get balance for given owner address
  //
  /*function participate(address _participant, uint256 _value) constant returns (bool success) {
    require(verifyActiveEvent());

    if(transferFrom(_participant, prizePool, _value)) {
      participants[currentEvent].push(_participant);
      participantTokens[currentEvent].push(_value);
    }

    return true;
  }*/


  // Get balance for given owner address
  //
  /*function startEvent() constant returns (bool success) {
    uint currentDateTime = now;

    // Initially start a new event with no winners, starting now and ending in
    // 7 days from today
    //
    events[currentEvent] = Event({
      startTime: currentDateTime,
      endTime: currentDateTime + eventDuration,
      prizePoolSupply: 0
    });

    return true;
  }*/


  // Generate multiple entries using an interval simulator. The random number will be
  // inside the [0, entryTotal) interval. The entryUpperBound variable simulates
  // the closed upper bound of the interval.
  //
  /*function endEvent() constant returns (bool success) {
    uint256 entryTotal;
    uint256 entryUpperBound;

    // Calculate total number of entries based on how many participant tokens
    // there are in the current game
    //
    for(uint participantIndex = 0; participantIndex < participants[currentEvent].length; participantIndex++) {
      entryTotal += participantTokens[currentEvent][participantIndex];
    }

    // Create multiple entries for each participant to simulate multiple
    // distributed chances
    //
    for(uint winnerIndex = 0; winnerIndex < winnerCount; winnerIndex++) {
      uint winningEntry = getRandomWinner(1, entryTotal);

      for(participantIndex = 0; participantIndex < participants[currentEvent].length; participantIndex++) {
        entryUpperBound += participantTokens[currentEvent][participantIndex];

        // If the winning entry is inside the [tokensLowerBound, tokensUpperBound)
        // interval, choose the current participant as a winner
        //
        if (winningEntry < entryUpperBound) {
          winners[currentEvent].push(participants[currentEvent][participantIndex]);
          break;
        }
      }
    }

    currentEvent += 1;
    return true;
  }*/

  // Generates a random number from 0 to participant shares count based on the
  // last block hash
  //
  function getRandomWinner(uint _seed, uint _max) constant returns (uint randomNumber) {
      return(uint(sha3(block.blockhash(block.number - 1), _seed )) % _max);
  }


  // Get balance for given owner address
  //
  function verifyActiveEvent() constant returns (bool success) {
    require(events[currentEvent].endTime >= now);
    return true;
  }
}
