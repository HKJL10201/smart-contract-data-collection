pragma solidity ^0.4.15;

import "./LowLevelStringManipulator.sol";
import "./MiniMeToken.sol";
import "./interface/IPollFactory.sol";
import "./interface/IPollContract.sol";

contract MiniMePoolToken is LowLevelStringManipulator, MiniMeToken {

  event Vote(uint indexed idPoll, address indexed _voter, bytes32 ballot, uint amount);
  event Unvote(uint indexed idPoll, address indexed _voter, bytes32 ballot, uint amount);
  event PollCanceled(uint indexed idPoll);

  function MiniMePoolToken (
    address _tokenFactory,
    address _parentToken,
    uint _parentSnapShotBlock,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol,
    bool _transfersEnabled
  ) MiniMeToken(_tokenFactory, _parentToken, _parentSnapShotBlock, _tokenName, _decimalUnits, _tokenSymbol, _transfersEnabled) {}

  struct VoteLog {
    bytes32 ballot;
    uint amount;
  }

  struct Poll {
    uint startBlock;
    uint endBlock;
    address token;
    address pollContract;
    bool canceled;
    mapping(address => VoteLog) votes;
  }

  Poll[] _polls;

  function addPoll(
    address _token,
    uint _startBlock,
    uint _endBlock,
    address _pollFactory,
    bytes _description) onlyController returns (uint _idPoll)
  {
    require(_endBlock > _startBlock);
    require(_endBlock > getBlockNumber());
    _idPoll = _polls.length;
    _polls.length++;
    Poll storage p = _polls[_idPoll];
    p.startBlock = _startBlock;
    p.endBlock = _endBlock;

    var (name,symbol) = getTokenNameSymbol(_token);
    string memory proposalName = strConcat(name , "_", uint2str(_idPoll));
    string memory proposalSymbol = strConcat(symbol, "_", uint2str(_idPoll));

    p.token = tokenFactory.createCloneToken(
      _token,
      _startBlock - 1,
      proposalName,
      MiniMeToken(_token).decimals(),
      proposalSymbol,
      true);

    p.pollContract = IPollFactory(_pollFactory).create(_description);

    assert(p.pollContract != 0);
  }

  function cancelPoll(uint _idPoll) onlyController {
    assert(_idPoll < _polls.length);
    Poll storage p = _polls[_idPoll];
    assert(getBlockNumber() < p.endBlock);
    p.canceled = true;
    PollCanceled(_idPoll);
  }

  function vote(uint _idPoll, bytes32 _ballot) {
    require(_idPoll < _polls.length);
    Poll storage p = _polls[_idPoll];
    assert(getBlockNumber() >= p.startBlock);
    assert(getBlockNumber() < p.endBlock);
    assert(!p.canceled);

    unvote(_idPoll);

    uint amount = MiniMeToken(p.token).balanceOf(msg.sender);

    assert(amount != 0);

    //enableTransfers = true;
    assert(MiniMeToken(p.token).transferFrom(msg.sender, address(this), amount));
    //enableTransfers = false;

    p.votes[msg.sender].ballot = _ballot;
    p.votes[msg.sender].amount = amount;

    assert(IPollContract(p.pollContract).deltaVote(int(amount), _ballot));

    Vote(_idPoll, msg.sender, _ballot, amount);
  }

  function unvote(uint _idPoll) {
    assert(_idPoll < _polls.length);
    Poll storage p = _polls[_idPoll];
    assert(getBlockNumber() >= p.startBlock);
    assert(getBlockNumber() < p.endBlock);
    assert(!p.canceled);

    uint amount = p.votes[msg.sender].amount;
    bytes32 ballot = p.votes[msg.sender].ballot;
    if (amount == 0) {
      revert();
    }

    assert(IPollContract(p.pollContract).deltaVote(-int(amount), ballot));

    p.votes[msg.sender].ballot = 0x0;
    p.votes[msg.sender].amount = 0;

    //enableTransfers = true;
    assert(MiniMeToken(p.token).transferFrom(address(this), msg.sender, amount));
    //enableTransfers = false;

    Unvote(_idPoll, msg.sender, ballot, amount);
  }

  // Constant Helper Function

  function nPolls() constant returns(uint) {
    return _polls.length;
  }

  function poll(uint _idPoll) constant returns(
    uint _startBlock,
    uint _endBlock,
    address _token,
    address _pollContract,
    bool _canceled,
    bytes32 _pollType,
    string _question,
    bool _finalized,
    uint _totalCensus
  ) {
    require(_idPoll < _polls.length);
    Poll storage p = _polls[_idPoll];
    _startBlock = p.startBlock;
    _endBlock = p.endBlock;
    _token = p.token;
    _pollContract = p.pollContract;
    _canceled = p.canceled;
    _pollType = IPollContract(p.pollContract).pollType();
    _question = getString(p.pollContract, bytes4(sha3("question()")));
    _finalized = (!p.canceled) && (getBlockNumber() >= _endBlock);
    _totalCensus = MiniMeToken(p.token).totalSupply();
  }

  function getVote(uint _idPoll, address _voter) constant returns (bytes32 _ballot, uint _amount) {
    require(_idPoll < _polls.length);
    Poll storage p = _polls[_idPoll];

    _ballot = p.votes[_voter].ballot;
    _amount = p.votes[_voter].amount;
  }

  function getBlockNumber() internal constant returns (uint) {
    return block.number;
  }
}
