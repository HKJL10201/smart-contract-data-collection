pragma solidity ^0.5.0;

contract MyStringStore {
  mapping (uint => uint) dieLeft;

  uint public currentTurn;
  uint public roundStarter;

  bool gameStarted;
  bool public gameOver;

  bool public fetchable;

  /// Payment pool to be paid to the winner at the end
  uint pool;

  /// Keep addressMap and reverseAddressMap for mapping the turns to addresses
  mapping(uint => address payable) addressMap;
  mapping(address => uint) reverseAddressMap;

  /// public face and bets
  uint public face;
  uint public bet;

  uint public roundWinner;
  uint public roundLoser;

  mapping(address => uint) hashedRolls1;
  mapping(address => uint) hashedRolls2;
  mapping(address => uint) hashedRolls3;
  mapping(address => uint) hashedRolls4;
  mapping(address => uint) hashedRolls5;

  mapping(uint => uint) counts;

  /// constructor initialises the state of the game before starting
  constructor () public {
    fetchable = false;
    gameStarted = false;
    gameOver = false;
    dieLeft[1] = 5;
    dieLeft[2] = 5;
    dieLeft[3] = 5;
    dieLeft[4] = 5;
    dieLeft[5] = 5;
    resetRound(1);
  }

  /// registerPlayer for registering the player before starting the game
  /// unregistered players will not be allowed in the game after the game has begun.
  function registerPlayer(uint player) public {
    require(gameStarted == false, "Game has already begun, cannot register now");
    addressMap[player] = msg.sender;
    reverseAddressMap[msg.sender] = player;
  }

  /// resetRound to reset after termination of each round, i.e. after a challenge has been called.
  function resetRound(uint firstplayer) private {
    // randomly initialise a face value
    face = (uint(keccak256(abi.encodePacked(now)))%6) + 1;
    bet = 0;
    currentTurn = firstplayer;
    roundStarter = firstplayer;

    counts[1] = 0;
    counts[2] = 0;
    counts[3] = 0;
    counts[4] = 0;
    counts[5] = 0;

    pool = 0;
  }
  
  /// callPrev for challenging the outcome of the last bet.
  function callPrev() public {
    require(msg.sender == addressMap[currentTurn], "Not your turn");
    require(dieLeft[currentTurn] > 0, "Dice over for you, game over");
    require(currentTurn != roundStarter, "Person who started the round cannot call the bet of the previous player");
    require(!gameOver, "game is over");

    // getRoundWinner is private to not disclose the winner prematurely
    getRoundWinner();
  }

  /// getRandom to fetch a random number using a nonce and the timestamp of the block
  function getRandom(address addr, uint nonce, uint key) view private returns (uint) {
    return (uint(keccak256(abi.encodePacked(now, addr, nonce*key)))%6) + 1;
  }

  /// roll function is a playable event to roll the dice.
  /// to keep the rolls secret, no one must know the outcome of the rolls,
  /// so we use random number generation inside solidity for the same.
  function roll(uint nonce, uint incomingbet) public payable {
    require(msg.sender == addressMap[currentTurn], "Not your turn");

    // dont let a player play if all his lives are over
    require(dieLeft[currentTurn] > 0, "Dice over for you, game over");

    require(dieLeft[currentTurn] > 0, "Dice over for you, game over");
    require(incomingbet >= bet, "illegal bid");
    require(msg.value >= 5, "Minimum pay is 5 wei");
    require(!gameOver, "game is over");

    uint rnd = getRandom(msg.sender, nonce, 1);
    hashedRolls1[msg.sender] = rnd;
    counts[rnd] += 1;

    rnd = getRandom(msg.sender, nonce, 2);
    hashedRolls2[msg.sender] = rnd;
    counts[rnd] += 1;

    rnd = getRandom(msg.sender, nonce, 3);
    hashedRolls3[msg.sender] = rnd;
    counts[rnd] += 1;

    rnd = getRandom(msg.sender, nonce, 4);
    hashedRolls4[msg.sender] = rnd;
    counts[rnd] += 1;

    rnd = getRandom(msg.sender, nonce, 5);
    hashedRolls5[msg.sender] = rnd;
    counts[rnd] += 1;

    bet = incomingbet;
    pool += msg.value;

    currentTurn %= 4;
    currentTurn += 1;

    if (dieLeft[currentTurn] == 0) {
      currentTurn %= 4;
      currentTurn += 1;
    }

    if (dieLeft[currentTurn] == 0) {
      currentTurn %= 4;
      currentTurn += 1;
    }

    if (dieLeft[currentTurn] == 0) {
      gameOver = true;
    }

    gameStarted = true;
    fetchable = false;
    roundStarter = 0;
  }

  /// Transfer the payment pool to the winner of each round.
  function transferPool(uint player) private {
    addressMap[player].transfer(pool);
    pool = 0;
  }

  /// revealDie to reveal the dice of all the players only AFTER the termination of the round.
  /// termination of round kept in check with the fetchable variable
  function revealDie() public view returns (uint[5] memory) {
    require(fetchable, "Can\'t view dice right now");
    return([hashedRolls1[msg.sender], hashedRolls2[msg.sender],
        hashedRolls3[msg.sender], hashedRolls4[msg.sender], hashedRolls5[msg.sender]]);
  }

  function lives() public view returns (uint[5] memory) {
    return ([dieLeft[1], dieLeft[2], dieLeft[3], dieLeft[4], dieLeft[5]]);
  }

  /// getRoundWinner evaluates the winner as well as the loser of the round.
  /// The money pool is transferred to the winner.
  /// The loser loses a dice.
  function getRoundWinner() private {
    if (counts[face] >= bet) {
      uint player = currentTurn - 1;
      if (player == 0) player = 4;

      transferPool(player);
      roundWinner = player;
      roundLoser = currentTurn;
      dieLeft[roundLoser] -= 1;
      resetRound(player);
    } else {
      uint player = currentTurn - 1;
      if (player == 0) player = 4;

      transferPool(currentTurn);
      roundWinner = currentTurn;
      roundLoser = player;
      dieLeft[roundLoser] -= 1;
      resetRound(currentTurn);
    }
    fetchable = true;
  }
}
