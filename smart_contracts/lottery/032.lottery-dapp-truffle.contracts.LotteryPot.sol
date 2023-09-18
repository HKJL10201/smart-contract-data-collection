pragma solidity 0.5.4;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @author Jimmy Chu
/// @title Lottery Pot Contract
contract LotteryPot is Ownable {
  using SafeMath for uint;

  // Pot closed time has to be at least 5 mins from current.
  uint constant MIN_DURATION = 300;

  // Basic info
  string public potName;
  uint public closedDateTime;
  uint public minStake;
  uint public totalStake;

  // equalShare - everyone has equal chance of winning in the pot.
  //   If there are x people in the pot, each winning chance is 1/x.
  //
  // weightedShare - winning chance is determined by how much a player
  //   contributed to the pot.
  //   If there are three players, contributing [x, y, z] amount to the pot,
  //   player 2 has the winning chance of y/(x+y+z).
  enum PotType { equalShare, weightedShare }
  PotType public potType;

  enum PotState { open, closed, stakeWithdrawn }
  PotState public potState;

  address public winner;

  // circuit-breaker can only be called from the factory. So we want to
  //   save the factory address down.
  address public factoryAddr;

  // allow the public to query if this factory contract is enabled.
  bool public enabled;

  // Pot stakes - using mapping iterator pattern.
  // To keep privacy, we don't allow user to query for participant stakes directly.
  // But we have a myStake() method allowing participant to query his own stake.
  mapping(address => uint) private participantStakes;
  address[] public participants;

  // --- Events Declaration ---

  event ParticipantJoin(
    address indexed participant
  );

  event ParticipantWithdraw(
    address indexed participant
  );

  event WinnerDetermined(
    address indexed winner
  );

  event WinnerWithdraw(
    address indexed winner,
    uint indexed totalStake
  );

  event LotteryPotEnabled(
    bool indexed enabled
  );

  // --- Functions Modifier ---

  modifier aboveMinStake {
    require(msg.value >= minStake);
    _;
  }

  modifier timeTransitions {
    if (now > closedDateTime && potState == PotState.open) {
      nextState();
    }
    _;
  }

  modifier atState(PotState state) {
    require(potState == state);
    _;
  }

  modifier notAtState(PotState state) {
    require(potState != state);
    _;
  }

  modifier onlyBy(address addr) {
    require(addr != address(0) && addr == msg.sender);
    _;
  }

  modifier participantHasStake(address sender) {
    require(participantStakes[sender] > 0);
    _;
  }

  modifier transitionNext() {
    _;
    nextState();
  }

  // circuit-breaker pattern
  modifier isEnabled {
    require(enabled);
    _;
  }

  modifier isDisabled {
    require(!enabled);
    _;
  }
  // --- end: circuit-breaker pattern

  /// Create a new LotteryPot contract
  /// @param _potName - Name of the lottery pot
  /// @param _duration - The duration of the pot `open` period
  /// @param _minStake - The minimum stake required to join the lottery pot
  /// @param _potType - type of the pot
  /// @param _owner - the owner to be recognized by this contract. Not necessarily `msg.sender` nor `tx.origin` for flexibility.
  constructor (
    string memory _potName,
    uint _duration,
    uint _minStake,
    PotType _potType,
    address _owner
  )
    public payable
  {
    require(_minStake > 0, "The minimum stake has to be greater than 0.");
    require(msg.value >= _minStake);
    require (_duration >= MIN_DURATION);

    enabled = true;
    potName = _potName;
    closedDateTime = now.add(_duration);
    minStake = _minStake;
    potType = _potType;
    potState = PotState.open;

    // Lottery Pot creation should be called from its factory.
    factoryAddr = msg.sender;
    totalStake = 0;

    // Transfer ownership to the owner, because it defaults to msg.sender
    //   by OpenZeppelin
    if (_owner != msg.sender) {
      transferOwnership(_owner);
    }

    // The creator also need to participate in the game.
    participate(_owner);
  }

  /// For a player to join in the game.
  /// @dev Note that we also allow an existing participant to add stake into the game.
  /// @param participant - address of the participant
  function participate(address participant) public payable
    isEnabled
    timeTransitions
    aboveMinStake
    atState(PotState.open)
  {
    // This is a new participant, push into the array
    if (participantStakes[participant] == 0) {
      participants.push(participant);
    }
    participantStakes[participant] = participantStakes[participant].add(msg.value);
    totalStake = totalStake.add(msg.value);
    emit ParticipantJoin(participant);
  }

  /// Convenient method for `msg.sender` to participate in the game.
  function participate() public payable {
    participate(msg.sender);
  }

  /// Fallback function defaults to participating in the game.
  function () external payable {
    participate(msg.sender);
  }

  /// Internal function for advancing the pot state.
  function nextState() internal {
    potState = PotState(uint(potState) + 1);
  }

  /// Retrieving number of participants in the game
  /// @return Number of participants in the game
  function totalParticipants() external view returns(uint) {
    return participants.length;
  }

  /// Determine the winner of the pot, actual algorithm is delegated to an internal function
  /// @dev Purposefully make this function allowed to be run by anybody, not just the contract owner.
  /// @return Address of the winner
  function determineWinner() public
    isEnabled
    timeTransitions
    atState(PotState.closed)
    returns(address)
  {
    if (winner != address(0)) return winner;

    winner = determineWinnerInternal();
    emit WinnerDetermined(winner);
    return winner;
  }

  /// Determine the winner of the lottery pot.
  /// @return Address of the winner
  function determineWinnerInternal() internal view returns(address) {
    // Dealing with equalShare
    if (potType == PotType.equalShare) {
      uint index = getRandom(participants.length);
      return participants[index];
    }

    // Dealing with weightedShare
    uint remaining = getRandom(totalStake);
    uint index = 0;
    while (remaining > participantStakes[participants[index]]) {
      remaining = remaining.sub(participantStakes[participants[index]]);
      index += 1;
    }
    return participants[index];
  }

  /// Generate a random value
  /// @param len - the generated value is between 0 to len, exclusively.
  /// @return A random number
  function getRandom(uint len) internal view returns(uint) {
    // Note: We are aware that miners can tweak the timestamp within 15s to
    //   calc. result potentially favorable to them, so we also use
    //   `block.difficulty` and `block.number` to add randomness that cannot
    //   be controlled by miners.

    return uint(keccak256(abi.encodePacked(
      block.timestamp,
      block.number,
      block.difficulty
    ))).mod(len);
  }

  /// Allowing winner to withdraw money.
  /// @dev in order to prevent withrawal address is a malicious contract, we use check-effect-interaction pattern inside.
  function winnerWithdraw() public
    isEnabled
    atState(PotState.closed)
    onlyBy(winner)
    transitionNext
  {
    // Using check-effect-interaction pattern
    // 1. Check - done by modifiers

    // Invariant check: make sure the contract has enough balance to be withdrawn from.
    assert(address(this).balance >= totalStake);

    // 2. Effect
    //   But we still want to transition to next state only after successful
    //   winner withdrawal.
    uint stake = totalStake;

    // we don't reset totalStake to 0, so we have a record of how big the
    //   lottery pot is.

    // 3. Interaction
    msg.sender.transfer(stake);
    emit WinnerWithdraw(msg.sender, stake);
  }

  /// Allow participant to check his own stake
  /// @return stake of the `msg.sender` in the pot
  function myStake() public view returns(uint) {
    return participantStakes[msg.sender];
  }

  /// Disable this contract.
  /// Once a contract is disabled, it cannot be enable back.
  /// @dev Only honor request called from its factory, so only the platform admin should call this method.
  /// @return `enabled` status of this contract
  function disableContract() public onlyBy(factoryAddr) returns(bool) {
    enabled = false;
    emit LotteryPotEnabled(enabled);
    return enabled;
  }

  /// Allow participants to withdraw money when contract is rendered disabled
  /// @dev Also want to check participants are not withdrawing from a pot that have all stakes withdrawn.
  function participantWithdraw() public
    isDisabled
    timeTransitions
    notAtState(PotState.stakeWithdrawn)
    participantHasStake(msg.sender)
  {
    // Using check-effect-interaction pattern
    // 1. Check - done by modifiers

    // Invariant check: make sure the contract has enough balance to be withdrawn from.
    assert(address(this).balance >= participantStakes[msg.sender]);

    // 2. Effect - set the participantStake = 0
    uint stake = participantStakes[msg.sender];
    participantStakes[msg.sender] = 0;

    // 3. Interaction - tranfer
    msg.sender.transfer(stake);
    emit ParticipantWithdraw(msg.sender);
  }
}
