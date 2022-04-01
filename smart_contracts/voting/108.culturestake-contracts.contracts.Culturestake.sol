pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import './Admin.sol';
import './Question.sol';
import "./Proxy.sol";

/// @title Culturestake admin hub
/// @author Sarah Friend @ana0
/// @notice Deploys questions and manages festivals and voting booths within the culturestake system
contract Culturestake is Admin {
  using SafeMath for uint256;

  mapping (bytes32 => Festival) festivals;
  mapping (bytes32 => QuestionStruct) questions;
  mapping (address => VotingBooth) votingBooths;
  mapping (address => bool) public questionsByAddress;
  address public questionMasterCopy;
  address public voteRelayer;

  struct VotingBooth {
    bool inited;
    bool deactivated;
    bytes32 festival;
    mapping (uint256 => bool) nonces;
  }

  struct Festival {
    bool inited;
    bool deactivated;
    uint256 startTime;
    uint256 endTime;
  }

  struct QuestionStruct {
    bool inited;
    bool deactivated;
    address contractAddress;
    bytes32 festival;
    uint256 maxVoteTokens;
  }

  event InitQuestion(bytes32 indexed question, bytes32 indexed festival, address indexed questionAddress);
  event InitFestival(bytes32 indexed festival, uint256 startTime, uint256 endTime);
  event InitVotingBooth(bytes32 indexed festival, address indexed boothAddress);

  event DeactivateQuestion(bytes32 indexed question);
  event DeactivateFestival(bytes32 indexed festival);
  event DeactivateVotingBooth(address indexed boothAddress);

  event ProxyCreation(Proxy proxy);

  /// @return True if the caller is a question contract deployed by this admin hub
  modifier onlyQuestions() {
      require(questionsByAddress[msg.sender], "Method can only be called by questions");
      _;
  }

  /// @dev The owners array is used in the Admin contract this inherits from
  /// @param _owners An array of all addresses that have admin permissions over this contract
  /// @param _questionMasterCopy The address of the master copy that holds the logic for each question
  constructor(address[] memory _owners, address _questionMasterCopy) public Admin(_owners) {
    questionMasterCopy = _questionMasterCopy;
  }

  /// @dev Provided the setup parameters of a question contract don't change, the logic on future questions can be updated
  /// @param _newQuestionMasterCopy The address of the master copy to use for new questions
  function setQuestionMasterCopy(address _newQuestionMasterCopy) public authorized {
    questionMasterCopy = _newQuestionMasterCopy;
  }

  /// @dev The vote relayer is the server key that sends votes to question contracts. It should be cycled periodically and must be set before any votes can take place
  /// @param _newVoteRelayer The address of the new vote relayer
  function setVoteRelayer(address _newVoteRelayer) public authorized {
    voteRelayer = _newVoteRelayer;
  }

  /// @dev Used by question contracts to validate the vote relayer
  /// @param _sender The address being challenged
  /// @return True if the address given is the current vote relayer
  function isVoteRelayer(address _sender) public view returns (bool) {
    return _sender == voteRelayer;
  }

  /// @dev Used by server to validate vote data
  /// @param _festival The festival chain id
  /// @return True if the festival is currently open for voting
  function isActiveFestival(bytes32 _festival) public view returns (bool) {
    // case festival has not been inited
    if (!festivals[_festival].inited) return false;
    // case festival has been manually deactivated
    if (festivals[_festival].deactivated) return false;
    // case festival hasn't started
    if (festivals[_festival].startTime > block.timestamp) return false;
    // case festival has ended
    if (festivals[_festival].endTime < block.timestamp) return false;
    return true;
  }

  /// @dev Used by server to validate vote data - the booth signs the answers array and a nonce
  /// @param _festival The festival chain id
  /// @param _answers An array of answer ids
  /// @param _nonce A random number added to the answers array by the booth - prevents a booth signature from being used for more than one vote package
  /// @param sigV Booth signature data
  /// @param sigR Booth signature data
  /// @param sigS Booth signature data
  /// @return True if the signature provided is a signature of an active booth, signing the correct data, and active on the claimed festival
  function checkBoothSignature(
    bytes32 _festival,
    bytes32[] memory _answers,
    uint256 _nonce,
    uint8 sigV,
    bytes32 sigR,
    bytes32 sigS
  ) public view returns (address) {
      bytes32 h = getHash(_answers, _nonce);
      address addressFromSig = ecrecover(h, sigV, sigR, sigS);
      // case is not a booth
      if (!votingBooths[addressFromSig].inited) return address(0);
      // case was manually deactivated
      if (votingBooths[addressFromSig].deactivated) return address(0);
      // case is from the wrong festival
      if (!(votingBooths[addressFromSig].festival == _festival)) return address(0);
      // case nonce has been used
      if (!isValidVotingNonce(addressFromSig, _nonce)) return address(0);
      return addressFromSig;
  }

  /// @param _answers An array of answer ids
  /// @param _nonce A random number added to the answers array by the booth
  /// @return Keccak sha3 of the packed answers array and nonce
  function getHash(
    bytes32[] memory _answers,
    uint256 _nonce
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(_answers, _nonce));
  }

  /// @dev Destructive method that burns the nonce
  /// @param _booth The booth using the nonce (nonces are stored per booth)
  /// @param _nonce The nonce
  function _burnNonce(address _booth, uint256 _nonce) internal {
    votingBooths[_booth].nonces[_nonce] = true;
  }

  /// @dev Destructive method that burns the nonce - marked onlyQuestions to prevent griefing
  /// @param _booth The booth using the nonce (nonces are stored per booth)
  /// @param _nonce The nonce
  function burnNonce(address _booth, uint256 _nonce) public onlyQuestions {
    _burnNonce(_booth, _nonce);
  }

  /// @dev Registers a voting booth with this contract
  /// @param _festival The festival chain is
  /// @param _booth The booth address
  function initVotingBooth(
    bytes32 _festival,
    address _booth
  ) public authorized {
      // booth are only for one festival
      require(festivals[_festival].inited, 'Festival must be inited');
      // booths are one-time use
      require(!votingBooths[_booth].inited, 'Voting booths can only be inited once');
      votingBooths[_booth].inited = true;
      votingBooths[_booth].festival = _festival;
      emit InitVotingBooth(_festival, _booth);
  }

  /// @dev Destructive method, signatures from deactivated booths can not be used to vote
  /// @param _booth The booth address
  function deactivateVotingBooth(address _booth) public authorized {
    votingBooths[_booth].deactivated = true;
    emit DeactivateVotingBooth(_booth);
  }

  /// @dev Getter for a voting booth struct
  /// @param _booth The booth address
  /// @return Bool for if the booth was initialized
  /// @return Bool for the if the booth was deactivated
  /// @return Chain id of the festival the booth was registered to
  function getVotingBooth(address _booth) public view returns (bool, bool, bytes32) {
    return (votingBooths[_booth].inited, votingBooths[_booth].deactivated, votingBooths[_booth].festival);
  }

  /// @dev Used by the server to validate vote data
  /// @param _booth The booth address
  /// @param _nonce The nonce
  /// @return True if the challenged booth has not used this nonce
  function isValidVotingNonce(address _booth, uint256 _nonce) public view returns (bool) {
    return (!votingBooths[_booth].nonces[_nonce]);
  }

  /// @dev Creates a festival
  /// @param _festival The chain id of the festival
  /// @param _startTime Timestamp for festival start
  /// @param _endTime Timestamp for festival end
  function initFestival(
    bytes32 _festival,
    uint256 _startTime,
    uint256 _endTime
  ) public authorized {
    // this method can only be called once per festival chain id
    require(!festivals[_festival].inited, 'Festival must be inited');
    require(_startTime >= block.timestamp);
    require(_endTime > _startTime);
    festivals[_festival].inited = true;
    festivals[_festival].startTime = _startTime;
    festivals[_festival].endTime = _endTime;
    emit InitFestival(_festival, _startTime, _endTime);
  }

  /// @dev Destructive method, questions from deactivated festivals cannot be voted on
  /// @param _festival The chain id of the festival
  function deactivateFestival(bytes32 _festival) public authorized {
    festivals[_festival].deactivated = true;
    emit DeactivateFestival(_festival);
  }

  /// @dev Getter for a festival struct
  /// @param _festival The chain id of the festival
  /// @return Bool for if the festival was initialized
  /// @return Bool for the if the festival was deactivated
  /// @return Timestamp for festival start time
  /// @return Timestamp for festival end time
  function getFestival(bytes32 _festival) public view returns (bool, bool, uint256, uint256) {
    return (
      festivals[_festival].inited,
      festivals[_festival].deactivated,
      festivals[_festival].startTime,
      festivals[_festival].endTime
    );
  }

  /// @dev Destructive method, deactivated questions cannot be voted on and do not pass the onlyQuestions modifier
  /// @param _question The question chain id
  function deactivateQuestion(bytes32 _question) public authorized {
    questions[_question].deactivated = true;
    questionsByAddress[questions[_question].contractAddress] = false;
    emit DeactivateQuestion(_question);
  }

  /// @dev Deploys a question contract
  /// @param _question The question chain id
  /// @param _maxVoteTokens The amount of vote tokens given to each voter per answer
  /// @param _festival The festival chain id
  function initQuestion(
    bytes32 _question,
    uint256 _maxVoteTokens,
    bytes32 _festival
  ) public authorized {
    require(festivals[_festival].inited, 'Festival must be inited');
    // this method can only be called once per question chain id
    require(!questions[_question].inited, 'This question can only be inited once');

    // encode the data used in the question setup method
    bytes memory data = abi.encodeWithSelector(
      0x2fa97de7, address(this), _question, _maxVoteTokens, _festival
    );

    // question contracts are a proxy of question master copy
    Proxy questionContract = createProxy(data);
    // store the question so it can be looked up by address in the onlyQuestions modifier
    questionsByAddress[address(questionContract)] = true;

    // store the question struct
    questions[_question].inited = true;
    questions[_question].festival = _festival;
    questions[_question].contractAddress = address(questionContract);
    questions[_question].maxVoteTokens = _maxVoteTokens;

    emit InitQuestion(_question, _festival, address(questionContract));
  }

  /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
  /// @param data Payload for message call sent to new proxy contract.
  /// @return The created proxy
  function createProxy(bytes memory data)
      internal
      returns (Proxy proxy)
  {
      proxy = new Proxy(questionMasterCopy);
      if (data.length > 0)
          // solium-disable-next-line security/no-inline-assembly
          assembly {
              if eq(call(gas, proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
          }
      emit ProxyCreation(proxy);
  }

  /// @dev Getter for a question struct
  /// @param _question The question chain is
  /// @return Bool for if the booth was initialized
  /// @return Bool for if the booth was deactivated
  /// @return The address of the question contract
  /// @return The festival chain id the question is associated with
  /// @return The maximum tokens given in this question per answer
  function getQuestion(bytes32 _question) public view returns (bool, bool, address, bytes32, uint256) {
    return (
      questions[_question].inited,
      questions[_question].deactivated,
      questions[_question].contractAddress,
      questions[_question].festival,
      questions[_question].maxVoteTokens
    );
  }
}