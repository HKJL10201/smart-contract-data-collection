pragma solidity 0.5.4;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./LotteryPot.sol";

/// @author Jimmy Chu
/// @title LotteryPot Contract Factory
contract LotteryPotFactory is Ownable {
  using SafeMath for uint;

  mapping(address => bool) lotteryPotsMapping;
  address[] public lotteryPots;

  // Allowing the public to query if this factory contract is enabled.
  bool public enabled;

  // --- Event Declaration ---
  event LotteryPotFactoryEnabled(
    bool indexed enabled
  );

  // --- Functions Modifier ---

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

  modifier createdByThisFactory(address potAddr) {
    require(lotteryPotsMapping[potAddr]);
    _;
  }

  /// Empty constructor
  constructor() public {
    enabled = true;
  }

  /// Create a new LotteryPot contract
  /// @dev The new LotteryPot contract is then saved in the array of this contract for future reference.
  /// @param potName - Name of the lottery pot
  /// @param duration - The duration of the pot `open` period
  /// @param minStake - The minimum stake required to join the lottery pot
  /// @param potType - refer to the LotteryPot contract for explaination
  /// @return The created LotteryPot contract
  function createLotteryPot(
    string memory potName, uint duration, uint minStake,
    LotteryPot.PotType potType
  )
  public payable
  isEnabled
  returns(LotteryPot) {
    // We also pass in the owner to be recognized by the contract, and ether amount
    //   for the owner to participate in the pot.
    LotteryPot newContract = (new LotteryPot).value(msg.value)({
      _potName: potName,
      _duration: duration,
      _minStake: minStake,
      _potType: potType,
      _owner: msg.sender
    });

    address newAddr = address(newContract);

    // Update with new contract info
    lotteryPots.push(newAddr);
    lotteryPotsMapping[newAddr] = true;
    return newContract;
  }

  /// Allow retrieving the the array of created contracts
  /// @return An array of all created LotteryPot contracts
  function getLotteryPots() public view returns(address[] memory) {
    return lotteryPots;
  }

  /// Toggling `enabled` status of this factory contract
  /// @dev Only honor request from this contract owner, aka, the platform admin.
  /// @return `enabled` status of this factory contract
  function toggleEnabled() public onlyOwner returns(bool) {
    enabled = !enabled;
    emit LotteryPotFactoryEnabled(enabled);
    return enabled;
  }

  /// Allow destruction of this factory contract
  /// @dev Only honor request from this contract owner, aka, the platform admin.
  function destroy() public onlyOwner isDisabled {
    selfdestruct(msg.sender);
  }

  /// Disable a LotteryPot contract created by this factory
  /// @dev Only honor request from this contract owner, aka, the platform admin.
  function disableLotteryPot(
    address payable potAddr
  )
  public
  onlyOwner
  createdByThisFactory(potAddr)
  returns(bool) {
    return LotteryPot(potAddr).disableContract();
  }

}
