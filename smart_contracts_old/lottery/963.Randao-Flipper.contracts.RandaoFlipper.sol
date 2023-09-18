pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

//contract FlipperGames {}
//contract FlipperConfigs {}
//contract FlipperRewards {}

contract RandaoFlipper is Ownable {

  // Owner payable address
  // sets in contract constructor
  address payable public ownerPayable;

  constructor() public {
    ownerPayable = msg.sender;
  }

  // GameCard configuration
  struct GameConfiguration {
    uint participantsNumber;
    uint winnersNumber;

    // After this block users will receive
    // rewards if anybody address will a winner.
    // Deposits of participants who did not
    // reveal, will be divided between winners addresses
    uint duration;
  }

  // Participant structure
  struct GameParticipant {
    bytes32 secret; // secret on each round
    bool revealed;
    bool commited;
    bool rewarded;
  }

  struct GameSession {
    uint id; // GameCard Id
    uint configId; // Configuration Id
    uint deposit; // Deposit to join
    // address owner; // Session owner

    // Random numbers collected from game participants
    // it is f(p1.num...pN.num)
    uint random;
    uint commitCounter;
    uint revealCounter;
    uint deadline;

    // Statuses of session
    bool ownerInvolved;
    bool completed;
    bool closed;

    // Participants data
    address[] participants;
    address[] winners;

    // For internal logic
    mapping(address => GameParticipant) _participants;
    mapping(address => bool) _winners;
  }

  // -------------------
  // GameCard sessions data
  // uint public GameCounter; // Number of games
  GameSession[] public GameSessions; // Games array

  // ---------------------
  // Configurations data
  // uint public ConfigurationsCounter;
  GameConfiguration[] public GameConfigurations;

  uint public ownerReward = 3; // Owner reward in percents
  uint public totalWinners;
  uint public totalFund;

  // ---------------------
  // Utils functions
  function encode(uint256 s, address sender) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(s, sender));
  }

  // ---------------------------
  // Create game configuration
  event GameConfigurationCreated(uint id);

  function createConfiguration(
    uint _participantsNumber,
    uint _winnersNumber,
    uint _duration
  ) onlyOwner external {
    uint configurationId = GameConfigurations.length++;
    GameConfiguration storage configuration = GameConfigurations[configurationId];

    configuration.participantsNumber = _participantsNumber;
    configuration.winnersNumber = _winnersNumber;
    configuration.duration = _duration;

    emit GameConfigurationCreated(configurationId);
  }

  function getConfigurationsCount() public view returns (uint configurationsCount) {
    return GameConfigurations.length;
  }

  // ------------------------
  // Create new game session
  // with selected configuration
  event GameCreated(uint id);

  modifier isValidConfiguration(uint configId) {
    require(
      GameConfigurations[configId].participantsNumber > 0,
      "Invalid game configuration Id"
    );
    _;
  }

  // Get game participants and winners arrays
  function getGame(uint gameId) external view returns (
    uint id,
    uint configId,
    uint deposit,
    uint random,
    uint commitCounter,
    uint revealCounter,
    uint deadline,
    bool ownerInvolved,
    bool completed,
    bool closed,
    address[] memory participants,
    address[] memory winners
  )
  {
    GameSession memory game = GameSessions[gameId];
    return (
      game.id,
      game.configId,
      game.deposit,
      game.random,
      game.commitCounter,
      game.revealCounter,
      game.deadline,
      game.ownerInvolved,
      game.completed,
      game.closed,
      game.participants,
      game.winners
    );
  }

  function getGameParticipant(uint gameId, address _participant) external view returns (
    bytes32 secret,
    bool revealed,
    bool commited,
    bool rewarded
  ) {
    GameParticipant memory participant = GameSessions[gameId]._participants[_participant];
    return (
      participant.secret,
      participant.revealed,
      participant.commited,
      participant.rewarded
    );
  }

  function getGamesCount() public view returns (uint gamesCount) {
    return GameSessions.length;
  }

  function createGame(
    uint _configId,
    bytes32 _secret,
    uint _deposit,
    bool _ownerInvolved
  ) onlyOwner
    isValidConfiguration(_configId)
    payable
    external
  {
    uint gameId = GameSessions.length++;

    require(_deposit > 0.1 ether, "A deposit cannot be small than 0.1 eth");

    // Create game
    GameSession storage game = GameSessions[gameId];
    GameConfiguration memory configuration = GameConfigurations[_configId];

    game.id = gameId;
    game.configId = _configId;
    game.deposit = _deposit;
    game.ownerInvolved = _ownerInvolved;
    game.completed = false;
    game.closed = false;
    game.commitCounter = 0;
    game.revealCounter = 0;
    game.participants = new address[](0);
    game.winners = new address[](0);
    game.random = 0;
    game.deadline = block.number + configuration.duration;

    // Owner will first participant if his involved
    if(_ownerInvolved) {
      game.participants.push(owner());
      game._participants[owner()] = GameParticipant(_secret, false, true, false);
      game.commitCounter++;
    }

    emit GameCreated(game.id);
  }

  // -------------------------
  // Common clients methods
  event NumberCommited(uint gameId, address participant);

  function commitNumber(uint gameId, bytes32 secret) payable external {
    GameSession storage game = GameSessions[gameId];
    GameConfiguration memory config = GameConfigurations[game.configId];

    require(!game.completed, "This game is already completed");
    require(!game.closed, "This game is already closed");
    require(game.deadline >= block.number, "This game was deadlined");
    require(msg.value == game.deposit, "msg.value should equal to game deposit");
    require(game.commitCounter < config.participantsNumber, "All participants are joined");
    require(!game._participants[msg.sender].commited, "You are commited");

    game.participants.push(msg.sender);
    game._participants[msg.sender] = GameParticipant(secret, false, true, false);
    game.commitCounter++;

    emit NumberCommited(gameId, msg.sender);
  }

  event NumberRevealed(uint gameId, address participant);

  function revealNumber(uint gameId, uint number) external {
    GameSession storage game = GameSessions[gameId];
    GameConfiguration memory config = GameConfigurations[game.configId];
    bytes32 secret = game._participants[msg.sender].secret;

    require(!game.completed, "This game is already completed");
    require(!game.closed, "This game is already closed");
    require(game.deadline >= block.number, "This game was deadlined");
    require(game.commitCounter == config.participantsNumber, "Not all participants are joined");
    require(game.revealCounter < config.participantsNumber, "All numbers are revealed");
    require(secret == encode(number, msg.sender), "Not valid number");
    require(!game._participants[msg.sender].revealed, "You are revealed your number");

    game.revealCounter++;
    game.random += number;
    game._participants[msg.sender].revealed = true;

    emit NumberRevealed(gameId, msg.sender);
  }

  // -------------------------------
  // Complete game method calculates
  // winners by common random number
  event GameCompleted(uint gameId, address[] winners);

  function completeGame(uint gameId) external {
    GameSession storage game = GameSessions[gameId];
    GameConfiguration memory config = GameConfigurations[game.configId];

    require(!game.completed, "This game is already completed");
    require(!game.closed, "This game is already closed");
    require(game.revealCounter > 0, "Nobody didn't reveal number, is impossible to select winners");
    require(
      game.revealCounter == config.participantsNumber || game.deadline <= block.number,
      "Not all participants revealed and the game deadline is not now"
    );

    // TODO refactor this
    uint random = (game.random + block.number) % config.participantsNumber;
    uint winnersNum = config.winnersNumber;

    while((random + winnersNum / 2) > game.participants.length) { random--; }
    while((random - winnersNum / 2 + 1) < 0) { random++; }

    bool takeRight = true;
    uint leftBias = random;
    uint rightBias = random;

    address winner;
    GameParticipant memory participant;

    for(uint i = 0; i < winnersNum; i++) {
      uint bias;
      if(takeRight) {
        bias = rightBias;
        takeRight = false;
        rightBias++;
      } else {
        leftBias--;
        bias = leftBias;
        takeRight = true;
      }

      winner = game.participants[bias];
      participant = game._participants[winner];

      if(participant.revealed) {
        game._winners[winner] = true;
        game.winners.push(winner);
        totalWinners++;
      }
    }
    // -----------------

    game.completed = true;

    emit GameCompleted(gameId, game.winners);
  }

  // -----------------------------
  // Close the failed game and makes
  // receive deposits to back are possible
  event GameClosed(uint gameId);

  function closeGame(uint gameId) external {
    GameSession storage game = GameSessions[gameId];

    require(!game.closed, "This game already is closed");
    require(!game.completed, "This game already is completed");
    require(game._participants[msg.sender].commited, "You are not game participant");
    require(
      game.deadline <= block.number && game.revealCounter == 0,
      "Not all participants revealed and the game deadline is not now"
    );

    game.closed = true;

    emit GameClosed(gameId);
  }

  // -----------------------------
  // After game is completed
  // users can get their rewards
  event RewardSent(uint gameId, address receiver, uint reward);
  event RewardSentOwner(uint gameId, uint reward);

  function getReward(uint gameId) external {
    GameSession storage game = GameSessions[gameId];
    GameParticipant storage participant = game._participants[msg.sender];

    require(game.completed, "Game is not completed");
    require(!participant.rewarded, "You are already rewarded");
    require(game._winners[msg.sender], "You address is not in winners");

    // Send reward
    uint prizePool = (game.deposit * game.participants.length);

    if(game.ownerInvolved) { prizePool = (game.deposit * (game.participants.length - 1)); }

    uint reward = (prizePool / game.winners.length);

    if(game.closed) {
      reward = game.deposit;
    } else {
      uint ownerRewardValue = reward / 100 * ownerReward;
      reward = reward - ownerRewardValue;

      require(ownerPayable.send(ownerRewardValue), "The contract cannot send reward to owner");
      emit RewardSentOwner(gameId, ownerRewardValue);
    }

    require(msg.sender.send(reward), "The contract cannot send reward to receiver");

    participant.rewarded = true;
    totalFund = totalFund + reward;

    emit RewardSent(gameId, msg.sender, reward);
  }

  event DepositGetBack(uint gameId, address receiver, uint deposit);

  function getBackDeposit(uint gameId) external {
    GameSession storage game = GameSessions[gameId];
    GameParticipant storage participant = game._participants[msg.sender];

    require(game.closed, "Game is not closed");
    require(!participant.rewarded, "You are already rewarded");
    require(participant.commited, "You are not commit number in this game");

    require(msg.sender.send(game.deposit), "The contract cannot send deposit back to receiver");

    participant.rewarded = true;

    emit DepositGetBack(gameId, msg.sender, game.deposit);
  }
}
