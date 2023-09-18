// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../../swap-thang/contracts/Token.sol";
import "./Ownable.sol";

/*
Voting dApp
-----------
1. Voting happens on the chain
2. Anyone can start an election and set a registraton time period and voting time period
3. Anyone can vote once on that election
4. Front end to vote/see results
5. Use Pango tokens to submit an election (100 PANGO)
6. To add yourself it costs 50 PANGO (and you can only add yourself once to the current election
7. The winner of the election gets 90% of the PANGO tokens
8. The user can vote in the election but costs 10 PANGO tokens to subit a vote (+ gas in ETH)
9. People who voted for the winner gets a percentage of the winnings.
10. Register to vote
*/

contract PollVote is Ownable {
  //variables
  string name = "PollVote";
  Token token;
  mapping (uint => mapping(uint => Poll)) polls;
  uint16 pollCount;

  constructor(Token memory _token) public {
    token = _token;
  }

  //enums
  enum PollStatus {
    REGISTRATION_PERIOD,
    VOTE_OPEN,
    VOTE_CLOSED,
    CANCELLED
  }

  //structs
  struct Time {
    uint open;
    uint closed;
  }

  struct Option {
    address wallet;
    string name;
  }

  struct Poll {
    Time registrationPeriod;
    Time votePeriod;
    Option[] options;
    uint optionCounter;
    PollStatus status;
    address creator;
  }

  //events

  //functions
  //the ability to change the token address
  function changeToken(Token _token) external onlyOwner {
    token = _token;
  }

  function queryRegistrationPolls() external view returns (Poll[] memory) {
    return _fetchPollsFromStatus(PollStatus.REGISTRATION_PERIOD);
  }

  function queryOpenPolls() external view returns (Poll[] memory) {
    return _fetchPollsFromStatus(PollStatus.VOTE_OPEN);
  }

  function queryClosedPolls() external view returns (Poll[] memory) {
    return _fetchPollsFromStatus(PollStatus.VOTE_CLOSED);
  }

  //help functions
  function _fetchPollsFromStatus(PollStatus ps) private view returns (Poll[] memory) {
    Poll[] memory tmp;
    uint idx = 0;
    for (uint256 index = 0; index < array.length; index++) {
      Poll memory p = polls[index];
      if (p.status == ps) {
        tmp[indx] = p;
        indx++;
      }
    }
    return tmp;
  }

  function _timeLeftToClosed(Time memory _time) private view returns (uint256) {
    return _time.closed - now;
  }

  function _timeLeftToOpen(Time memory _time) private view returns (uint256) {
    return _time.open - now;
  }

  function _withinPeriod(Time memory _time) private view returns (bool) {
    return now >= _time.open && now <= _time.closed;
  }
}
