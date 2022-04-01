pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";
import "openzeppelin-solidity/contracts/access/Whitelist.sol";
import "./interfaces/VoterRegistry.sol";

/// @title Voting Office
/// @dev Contract to manage multiple votings belonging to one registry
contract VotingOffice is SupportsInterfaceWithLookup, Whitelist{
  //The registry this contract is connected to
  VoterRegistry internal _voterRegistry;

  //Mapping of IDs to votings
  mapping(uint256 => Voting) internal votings;

  //Id that is assigned to the next voting created. Should also always equal the total number of votings
  uint256 public nextId;

  //Prefix that is used to compute URIs
  string public URIprefix;

  //Struct is comprised of all information about a voting
  struct Voting {
    string title;         //Title of the voting
    uint256 totalVotes;   //Total number of votes for this voting
    uint256[] votes;      //An array of votes per possible answer
    uint256 end;          //Block number at which the voting is closed
    bytes32 digest;       //SHA256 digest of the question and all answers (comma seperated list)

    //Stores for each address whether its vote was recorded here:
    mapping(address => bool) voters;
  }

  /// @dev This emits whenever a new voting is created.
  ///  Can be used to return the voting id through a listener (see test)
  event createdVote(
    uint256 _votingId
  );

  /// @dev This emits whenever a vote is sucessfully submitted
  event voteReceived(
    uint256 _votingId,
    address _voter
  );

  constructor(address __voterRegistry, string _URIprefix)
    public
  {
    //Instantiates registry as both, ÉRC165 interface and registry
    ERC165 _ERC165;
    _voterRegistry = VoterRegistry(__voterRegistry);
    _ERC165 = ERC165(__voterRegistry);

    //Checks target contract for ERC165 interface introspection (positive and negative
    bytes4 interfaceId_ERC165 = 0x01ffc9a7;
    bytes4 interfaceId_invalid = 0xffffffff;
    require(_ERC165.supportsInterface(interfaceId_ERC165), "Target contract does not implement ERC165");
    require(!_ERC165.supportsInterface(interfaceId_invalid), "Target contract does not implement ERC165");

    //Checks target contract for VoterRegistry interface
    bytes4 interfaceId_VoterRegistry = 0x312b5b94;
    require(_ERC165.supportsInterface(interfaceId_VoterRegistry), "Target contract does not implement VoterRegistry");

    //Stores URI prefix to compute URIs later on
    URIprefix = _URIprefix;

    //Adds the contract creator to the whitelist so that she can create new votings
    addAddressToWhitelist(owner);
  }

  /// @notice Reads the address of the corresponding registry
  /// @return Address of the VoterRegistry this office belongs to
  function getVotersRegistry() external view returns (address) {
    return _voterRegistry;
  }

  /// @notice Starts a new voting
  /// @param _title Title of the new voting
  /// @param _options Number of answers that are possible for the new voting
  /// @param _end Block number at which the voting is closed
  /// @param _digest SHA256 digest of the question and all answers (in a comma seperated list)
  function newVoting(
    string _title,
    uint8 _options,
    uint256 _end,
    bytes32 _digest
  )
    external
    onlyIfWhitelisted(msg.sender)
    returns (uint256)
  {
    require(_options > 1, "Votes need at least two possible answers");
    require(_end > block.number, "End block number is lower than current block number");

    //Stores an array with length = number of possible answers to record votes
    uint256[] memory votesArray= new uint256[](_options);

    //Stores the new voting
    votings[nextId] = Voting(_title, 0, votesArray, _end, _digest);

    //Emits event and increments nextId
    emit createdVote(nextId++);
  }

  /// @notice Reads the title of a voting
  /// @param _id ID of the voting
  /// @return Title of the voting
  function votingTitle(uint256 _id) external view returns(string) {
    require(isValidId(_id), "Voting does not exist.");

    return votings[_id].title;
  }

  /// @notice Reads the block number at which the voting is closed
  /// @param _id ID of the voting
  /// @return Block number at which the voting is closed
  function votingEnd(uint256 _id) external view returns(uint256) {
    require(isValidId(_id), "Voting does not exist.");

    return votings[_id].end;
  }

  /// @notice Reads the digest of the question and all possible answers
  /// @param _id ID of the voting
  /// @return Digest of the question and all possible answers
  function votingDigest(uint256 _id) external view returns(bytes32) {
    require(isValidId(_id), "Voting does not exist.");

    return votings[_id].digest;
  }

  /// @notice Checks whether an ID is valid
  /// @param _id ID to be checked
  /// @return True if the ID is valid
  function isValidId(uint256 _id) internal view returns(bool) {
    return (_id < nextId);
  }

  /// @notice Checks whether a voting is still active (not everyone has voted and the end block is not reached yet)
  /// @param _id Voting that should be checked
  /// @return True if the ID is still active
  function isActive(uint256 _id) public view returns(bool) {
    require(isValidId(_id), "Voting does not exist.");
    return (votings[_id].totalVotes < _voterRegistry.getNumberOfVoters() && block.number < votings[_id].end);
  }

  /// @notice Vote in a voting
  /// @param _id Voting that should be voted on
  /// @param _option Number of the option that should be voted for (starts at 0)
  function vote(uint256 _id, uint8 _option) external {
    require(isActive(_id), "This voting is already closed");
    require(!hasVoted(_id, msg.sender), "You already voted on this issue. Votes are final");
    require(votings[_id].votes.length > _option, "This option does not exist");

    votings[_id].totalVotes++;
    votings[_id].votes[_option]++;

    votings[_id].voters[msg.sender] = true;

    emit voteReceived(_id, msg.sender);
  }

  /// @notice Checks whether an address has already voted on a voting
  /// @param _id Voting that should be checked
  /// @param _voter Address that should be checked
  /// @return True if the voter has already voted
  function hasVoted(uint256 _id, address _voter) public view returns (bool) {
    require(_voterRegistry.isRegistered(_voter), "This address is not registered to vote here.");

    return votings[_id].voters[_voter];
  }

  /// @notice Counts the number of total votes in a voting
  /// @param _id Voting that should be looked at
  /// @return Total number of votes
  function totalVotes(uint256 _id) external view returns (uint256) {
    require(isValidId(_id), "Voting does not exist.");

    return votings[_id].totalVotes;
  }

  /// @notice Counts the number votes for each option
  /// @param _id Voting that should be looked at
  /// @return Array of number of votes, one number for each option
  /// @dev Use this for information purposes only
  function interimResults(uint256 _id) external view returns (uint256[]) {
    require(isValidId(_id), "Voting does not exist.");

    return votings[_id].votes;
  }

  /// @notice Counts the number votes for each option. Only works if the voting is concluded
  /// @param _id Voting that should be looked at
  /// @return Array of number of votes, one number for each option
  /// @dev Use this to base further decisions or processes on
  function finalResults(uint256 _id) external view returns (uint256[]) {
    require(isValidId(_id), "Voting does not exist.");
    require(!isActive(_id), "This voting is still ongoing");

    return votings[_id].votes;
  }
}
