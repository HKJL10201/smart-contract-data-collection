pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";
import "openzeppelin-solidity/contracts/access/Whitelist.sol";
import "./interfaces/VoterRegistry.sol";

/// @title Standard voting Voter Registry
/// @dev Registers and de-registers voters
contract DemocraticRegistry is VoterRegistry, SupportsInterfaceWithLookup, Whitelist {
  // Name of this registry
  string internal name;

  // Total number of voters that are registered here
  uint256 internal numberOfVoters;

  // Stores for each address whether it's registered here or not
  mapping (address => bool) voters;

  constructor(string _name)
    public
  {
    //Sets the name of this registry
    name = _name;

    //Registering ERC165 interface IDs
    bytes4 interfaceId_VoterRegistry = 0x312b5b94;
    bytes4 interfaceId_ERC165 = 0x01ffc9a7;
    _registerInterface(interfaceId_ERC165);
    _registerInterface(interfaceId_VoterRegistry);

    //Adding owner to whitelist
    addAddressToWhitelist(owner);
  }

  /// @notice Count all voters that are registered here
  /// @return The number of registered voters
  function getNumberOfVoters() external view returns (uint256) {
    return numberOfVoters;
  }

  /// @notice Reads the name of this registry
  /// @return The name of this registry
  function getName() external view returns (string) {
    return name;
  }

  /// @notice Checks whether an address is registered as voter
  /// @param _voter Address that should be checked
  /// @return True if the address is registered here
  function isRegistered(address _voter) public view returns (bool) {
    return voters[_voter];
  }

  /// @notice Registers a new voter
  /// @param _voter Address that should be registered
  /// @dev Emits a registrationChange, even if the address was already registered
  function registerVoter(address _voter) public onlyIfWhitelisted(msg.sender) {
    if(voters[_voter] == false) {
      numberOfVoters++;
    }
    voters[_voter] = true;
    emit registrationChange(_voter, true);
  }

  /// @notice Deregisters a voter
  /// @param _voter Address that should be deregistered
  /// @dev Emits a registrationChange, even if the address was not registered before
  function deregisterVoter(address _voter) public onlyIfWhitelisted(msg.sender) {
    if(voters[_voter] == true) {
      numberOfVoters--;
    }
    voters[_voter] = false;
    emit registrationChange(_voter, false);
  }

  /// @notice Executes registerVoter for each element of the passed array
  /// @param _voters Array of addresses that should be registered
  function registerVoters(address[] _voters) external {
    for (uint256 i = 0; i < _voters.length; i++) {
      registerVoter(_voters[i]);
    }
  }

  /// @notice Executes deregisterVoter for each element of the passed array
  /// @param _voters Array of addresses that should be deregistered
  function deregisterVoters(address[] _voters) external  {
    for (uint256 i = 0; i < _voters.length; i++) {
      deregisterVoter(_voters[i]);
    }
  }
}
