pragma solidity ^0.4.18;

contract Token {
  uint256 public totalSupply;

  function balanceOf(address _owner) public constant returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BetsToken is Token {

  struct Bet {
    uint id;
    address from;
    address against;
    string bet;
    uint date;
    uint amount;
    bool accepted;
    bool opened;
  }

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  string public version = '1.2';

  address public owner;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  Bet[] public bets;

  event NewBet(uint _bet);
  event UpdateBet(uint _bet);
  event AcceptBet(uint _bet);
  event CloseBet(uint _bet);
  event PayBet(uint _bet);

  function BetsToken(
    uint256 _initialAmount,
    string _tokenName,
    uint8 _decimalUnits,
    string _tokenSymbol
  ) public {
    owner = msg.sender;
    balances[msg.sender] = _initialAmount;
    totalSupply = _initialAmount;
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function drip(address _to) onlyOwner public returns (bool success) {
    return transfer(_to, 1);
  }
  function dripToMe() public returns (bool success) {
    require(balances[msg.sender] == 0);
    require(balances[owner] >= (totalSupply / 2));
    balances[msg.sender] += 1;
    balances[owner] -= 1;
    Transfer(owner, msg.sender, 1);
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(availableBalanceOf(msg.sender) >= _value);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(availableBalanceOf(_from) >= _value && allowed[_from][msg.sender] >= _value);
    balances[_to] += _value;
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function availableBalanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner] - debtOf(_owner);
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function bet(address _against, uint256 _amount, string _bet) public {
    require(_against != msg.sender);
    require(availableBalanceOf(msg.sender) >= _amount);
    require(_amount > 0);
    uint id = betsSize();
    bets.push(Bet({
      id: id,
      from: msg.sender,
      against: _against,
      amount: _amount,
      bet: _bet,
      date: now,
      accepted: false,
      opened: true
    }));
    NewBet(id);
    UpdateBet(id);
  }

  function acceptBet(uint _bet, bool _accept) public {
    require(bets[_bet].opened);
    require(bets[_bet].against == msg.sender);
    require(!bets[_bet].accepted);
    require(availableBalanceOf(msg.sender) >= bets[_bet].amount);
    if (_accept) {
      bets[_bet].accepted = true;
      AcceptBet(_bet);
    } else {
      bets[_bet].opened = false;
      CloseBet(_bet);
    }
    UpdateBet(_bet);
  }

  function cryAndForgotBet(uint _bet) public {
    require(bets[_bet].opened);
    require(bets[_bet].from == msg.sender);
    bets[_bet].opened = false;
    CloseBet(_bet);
    UpdateBet(_bet);
  }

  function giveMeTheMoney(uint _bet) public {
    require(bets[_bet].opened);
    require(bets[_bet].against == msg.sender);
    require(bets[_bet].accepted);
    bets[_bet].opened = false;
    transferBet(bets[_bet]);
    PayBet(_bet);
    UpdateBet(_bet);
  }

  function transferBet(Bet _bet) private returns (bool success) {
    require(balances[_bet.from] >= _bet.amount);
    balances[_bet.against] += _bet.amount;
    balances[_bet.from] -= _bet.amount;
    Transfer(_bet.from, _bet.against, _bet.amount);
    return true;
  }

  function myDebt() public constant returns (uint debt) {
    return debtOf(msg.sender);
  }

  function debtOf(address _owner) public constant returns (uint debt) {
    debt = 0;
    for (uint i = 0; i < bets.length; i++) {
      Bet memory b = bets[i];
      if (b.opened) {
        if (b.from == _owner || (b.against == _owner && b.accepted)) {
          debt += b.amount;
        }
      }
    }
    return debt;
  }

  function betsSize() public constant returns (uint) {
    return bets.length;
  }
}
