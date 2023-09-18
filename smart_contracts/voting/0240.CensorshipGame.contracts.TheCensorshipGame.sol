// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Bitwise.sol";
import "./ScoreList.sol";

/// @notice An on-chain, hidden role game featuring quadratic voting
///         that doesn't require zero knowledge proofs.
contract TheCensorshipGame is Ownable, ScoreList {

  event EndRound(uint256 round);
  event GameStarted(uint256 startTime, bytes32 randomSeed);
  event GameOver(address winner, uint256 winningTeam);
  event PlayerFlipped(address player);
  event PlayerRevealed(address player, uint256 team);

  struct Player {
    // keccak256(abi.encodePacked(seed, nonce))
    bytes32 commitment;
    // bitpacked: one bool per round
    uint64 didVote;
    // bitpacked: one bool per round
    uint64 didFlip;
    // type(uint64).max used as sentinel
    uint64 revealedRole;
    // display name in game
    string name;
    // flag for prize withdrawl
    bool withdrew;
  }

  uint256 immutable public PRIZE_POOL;
  uint256 constant REVEAL_ROUND_LENGTH = 2 minutes;
  uint256 constant VOTE_BUDGET         = 100;
  uint256 constant VOTE_ROUND_LENGTH   = 10 minutes;

  uint256 public blueTeamCount;
  uint256 public redTeamCount;
  // Timestamp of start of game
  uint256 public gameStart;
  // A public random seed that is combined with players' private seeds
  // to get their respective starting team.
  bytes32 public publicSeed;
  // Even rounds are voting rounds, odd rounds are reveal rounds
  uint256 public round;
  // Timestamp of lastet round started
  uint256 public roundTimer;
  // How many vote actions have occured this round 
  uint256 public roundVoteCount;
  string[] public names;
  address[] public players;
  mapping(address => Player) public playerDetails;

  constructor() payable {
    PRIZE_POOL = msg.value;
  }

    ///////////////
   // MODIFIERS //
  ///////////////
  
  /// @dev Checks that player's score is higher than this rounds cut off
  modifier notCensored() {
    if (round > 0) {
      require(
        scoreList[cutOffAddress].score <=
        scoreList[msg.sender].score,
        "YOU'VE BEEN REDACTED"
      );
    }
    _;
  }

  modifier gameStarted() {
    require(gameStart > 0, "GAME NOT STARTED");
    _;
  }

    ////////////////////////////////
   // PRIVLEDGED STATE MODIFYING //
  ////////////////////////////////
  
  /// @notice Allows owner to progress games with many dropouts
  function endRound() external onlyOwner {
    _endRound();
  }

  /// @notice Emergency recover prize money, in case of deadlocked game
  function recover() external onlyOwner {
    require(block.timestamp > gameStart + 1 days);
    msg.sender.call{value: address(this).balance}("");
  }

  /// @notice Initiliazes the game, starts first voting round
  /// @param randomSeed A public random seed that is combined with players' private
  ///                   seeds to get their respective starting team
  function startGame(bytes32 randomSeed) external onlyOwner {
    require(gameStart == 0);
    gameStart = block.timestamp;
    roundTimer = block.timestamp;
    publicSeed = randomSeed;
    cutOffPoint = scoreListLength - 1;
    cutOffAddress = scoreListTail;
    emit GameStarted(block.timestamp, randomSeed);
  }

    ////////////////////////////
   // PUBLIC STATE MODIFYING //
  ////////////////////////////
  
  /// @param commitment Equivalent to keccak256(abi.encodePacked(seed, nonce)) where
  ///                   seed and nonce are privately generated random 32byte values
  /// @param name The user's screen name in game (non-unique!)
  /// @dev Must be called before `startGame`
  function joinGame(bytes32 commitment, string calldata name) external {
    require(gameStart == 0);
    require(commitment != bytes32(0));
    require(playerDetails[msg.sender].commitment == bytes32(0));

    _append(msg.sender);
    players.push(msg.sender);
    names.push(name);
    playerDetails[msg.sender] = Player(
      commitment, 0, 0, type(uint64).max, name, false
    );
  }

  /// @dev Can only be called during even rounds
  /// @param saved A list of players you want to save, elements must be orderd and unique
  /// @param weights Voting weights corrensponding to the `saved` array, must total < 100
  /// @param flip If true, msg.sender will flip sides to the opposite team
  function voteToSave(
    address[] calldata saved,
    uint256[] calldata weights,
    bool flip
  ) external notCensored gameStarted {
    require(round % 2 == 0, "NOT A VOTING ROUND");
    require(
      playerDetails[msg.sender].didVote & 1 << (round/2) == 0,
      "ALREADY VOTED"
    );
    _validateVote(saved, weights);

    playerDetails[msg.sender].didVote |= uint64(1 << (round/2));

    for(uint256 i; i < saved.length; i++) {
      uint256 score =  uint64(Math.sqrt(10000*weights[i]));
      _updateScoreList(saved[i], scoreList[saved[i]].score + score);
    }

    if(flip) {
      _flip();
    }

    roundVoteCount++;
    if (
      roundVoteCount == cutOffPoint + 1 ||
      block.timestamp > roundTimer + VOTE_ROUND_LENGTH
    ) {
      _endRound();
    }
  }

  /// @notice Reveal the inputs to your commitment so your final color can be settled
  ///         not revealing within a time window results is disqualification for prize
  /// @dev Ends game when winning player reveals. Can only be called during even rounds.
  function reveal(bytes32 seed, bytes32 nonce) external gameStarted {
    // require that the caller has been "redacted" or is the winner of the game
    require(
      !stillAlive() ||
      (cutOffPoint == 0 && msg.sender == scoreList[SCORE_LIST_GUARD].next)
    );
    require(round % 2 == 1, "NOT A REVEAL ROUND");
    bytes32 commit = playerDetails[msg.sender].commitment;
    require(
      commit != bytes32(0) &&
      commit == keccak256(abi.encodePacked(seed,nonce)),
      "PROVIDED VALUES DON'T MATCH COMMITMENT"
    );
    require(
      playerDetails[msg.sender].revealedRole == type(uint64).max,
      "ALREADY REVEALED"
    );

    uint256 currTeam = _getCurrentTeam(seed, playerDetails[msg.sender].didFlip);
    playerDetails[msg.sender].revealedRole = uint64(currTeam);
    if (currTeam == 0) {
      redTeamCount++;
    } if (currTeam == 1) {
      blueTeamCount++;
    }

    if (cutOffPoint == 0 && msg.sender == scoreList[SCORE_LIST_GUARD].next) {
      emit GameOver(msg.sender, currTeam);
      return;
    }

    roundVoteCount++;
    if (
      block.timestamp > roundTimer + REVEAL_ROUND_LENGTH ||
      (roundVoteCount == cutOffPoint + 1 && cutOffPoint != 0)
    ) {
      _endRound();
    }

    emit PlayerRevealed(msg.sender, currTeam);
  }
  /// @notice Proportionally distributes the prize pool to every elligible member of
  ///         the winning team
  /// @dev Requires the winner to have already revealed
  function claimWinnings() external {
    require(playerDetails[msg.sender].withdrew == false, "ALREADY WITHDREW");
    require(cutOffPoint == 0, "GAME NOT OVER");

    uint256 winningTeam = playerDetails[scoreList[SCORE_LIST_GUARD].next].revealedRole;
    require(winningTeam < 2, "WINNER DIDNT REVEAL");
    require(winningTeam == playerDetails[msg.sender].revealedRole, "NOT A WINNER");

    uint256 amountOfWinners = winningTeam == 0 ? redTeamCount: blueTeamCount;
    playerDetails[msg.sender].withdrew = true;
    (bool success, ) = msg.sender.call{value: PRIZE_POOL/amountOfWinners}("");
    require(success);
  }

    /////////////////////////
   // CONVINIENCE GETTERS //
  /////////////////////////


  function didVote() external view returns (bool) {
    return playerDetails[msg.sender].didVote & 1 << (round/2) > 0;
  }

  function getMyColor(bytes32 seed) external view returns (uint256) {
    return _getCurrentTeam(seed, playerDetails[msg.sender].didFlip);
  }

  function getStartingTeam(bytes32 seed) public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, publicSeed))) % 2;
  }

  function namesList() external view returns (string[] memory) {
    return names;
  }

  function playersList() external view returns (address[] memory) {
    return players;
  }

  function stillAlive() public view returns (bool) {
    return scoreList[msg.sender].score >= scoreList[cutOffAddress].score;
  }

    ////////////////////////////////
   //      INTERNAL HELPERS      //
  ////////////////////////////////

  function _endRound() internal {
    // if the ending round is a voting round, move cut off point to
    // eliminate the bottom half of player
    if (round % 2 == 0) {
      cutOffPoint /= 2;
      cutOffAddress = _getIndex(cutOffPoint);
    }
    round++;
    roundVoteCount = 0;
    roundTimer = block.timestamp;
    emit EndRound(round);
  }

  function _flip() internal {
    require(
      playerDetails[msg.sender].didFlip & 1 << (round/2) == 0,
      "ALREADY FLIPPED"
    );

    playerDetails[msg.sender].didFlip |= uint64(1 << (round/2));
    emit PlayerFlipped(msg.sender);
  }

  function _getCurrentTeam(bytes32 seed, uint256 didFlip) internal view returns (uint256) {
    // an even amount of flips cancel out
    if (Bitwise._popCount(didFlip) % 2 == 0) {
      return getStartingTeam(seed);
    }
    // an odd amount of flips toggles
    return getStartingTeam(seed) ^ 1;
  }

  function _validateVote(
    address[] calldata saved,
    uint256[] calldata weights
  ) internal view {
    require(saved.length == weights.length, "MISMATCH LENGTHS");

    uint256 total;
    for (uint256 i; i < weights.length; i++) {
      total += weights[i];
    }
    require(total <= VOTE_BUDGET, "OVERSPENT VOTING POINTS");

    for(uint256 i; i < saved.length; i++) {
      require(msg.sender != saved[i], "NO SELF VOTING");
      // checks for duplicates
      if (i > 0) {
        require(uint160(saved[i - 1]) < uint160(saved[i]));
      }
    }
  }
}