pragma solidity ^0.4.24;

/// @title Standard Voter Registry
/// @dev ERC165 identifier for this interface is 0x312b5b94
interface VoterRegistry {
  /// @dev This emits whenever a registration is changed or reaffirmed
  event registrationChange (
    address _voter,
    bool indexed _newStatus
  );

  /// @notice Count all voters that are registered here
  /// @return The number of registered voters
  function getNumberOfVoters() external view returns (uint256);

  /// @notice Reads the name of this registry
  /// @dev Should be constant and set in the contructor
  /// @return The name of this registry
  function getName() external view returns (string);

  /// @notice Checks whether an address is registered as voter
  /// @param _voter Address that should be checked
  /// @return True if the address is registered here
  function isRegistered(address _voter) external view returns (bool);

  /// @notice Registers a new voter
  /// @param _voter Address that should be registered
  /// @dev Emits a registrationChange, even if the address was already registered
  function registerVoter(address _voter) external;

  /// @notice Deregisters a voter
  /// @param _voter Address that should be deregistered
  /// @dev Emits a registrationChange, even if the address was not registered before 
  function deregisterVoter(address _voter) external;
}
