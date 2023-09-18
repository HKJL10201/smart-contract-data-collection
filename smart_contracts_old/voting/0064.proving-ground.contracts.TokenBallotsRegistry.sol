pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./TokenBallot.sol";

contract TokenBallotsRegistry is Ownable {

  // ballots store - index is ballot id
  TokenBallot[] public ballots;

  // key: ballot id, value: ballot address - allows lookup by ballot registry id
  mapping (uint256 => address) public ballotsIds;

  // allows lookup by address
  mapping (address => TokenBallot) ballotsMap;

  // anyone can get a ballot - returns added ballot registry id
  function addBallot(TokenBallot _ballot) external returns(uint256) {

    assert (ballotsMap[_ballot] == address(0));

    var id = ballots.length;

    ballots.push(_ballot);
    ballotsMap[address(_ballot)] = _ballot;
    ballotsIds[id] = _ballot;
    BallotRegisteredEvent(_ballot.token(), id, _ballot);

    return id;
  }

  event BallotRegisteredEvent(address indexed token, uint256 id, address ballot);

  // array iteration helper
  function ballotsCount() external constant returns (uint256) {
    return ballots.length;
  }
}

