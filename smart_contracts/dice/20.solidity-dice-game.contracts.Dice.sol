// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Dice is VRFConsumerBase, Ownable, ReentrancyGuard {
 bytes32 internal keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4; // Polygon (MATIC) - Testnet
 address internal vrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255; // Polygon (MATIC) - Testnet
 IERC20 public token;
 uint8 public feePercent;
 uint256 public minBet;
 uint256 public maxBet;
 uint256 public totalBalances;
 uint256 public devBalance;
 address public devAddress;
 address zeroAddress = 0x0000000000000000000000000000000000000000;
 struct RequestBet{
  uint256 bet;
  uint8 guessNumber;
  uint256 realNumber;
  uint256 win;
 }
 mapping (bytes32 => RequestBet) public requestBets;
 mapping (address => uint256) public balances;
 event RequestRandomness(bytes32 indexed requestId, bytes32 keyHash, uint256 seed);
 event RequestRandomnessFulfilled(bytes32 indexed requestId, uint256 randomness);
 event eventDeposit(uint256 amount);
 event eventWithdraw(uint256 amount);
 event eventDevWithdraw(uint256 amount);
 event eventSetTokenAddress(address tokenAddress);
 event eventSetDevAddress(address devAddress);
 event eventSetMinBet(uint256 minBet);
 event eventSetMaxBet(uint256 maxBet);
 event eventResult(bool win, uint256 bet);

 constructor(address _tokenAddress, address _devAddress, uint256 _minBet, uint256 _maxBet, uint8 _feePercent) VRFConsumerBase(vrfCoordinator, _tokenAddress) {
  devAddress = _devAddress;
  token = IERC20(_tokenAddress);
  minBet = _minBet;
  maxBet = _maxBet;
  feePercent = _feePercent;
 }

 function rollDice(uint256 _bet, uint8 _guessNumber, uint256 _userProvidedSeed) public nonReentrant returns (bytes32 requestId) {
  require(_bet >= minBet, 'rollDice: Your bet has not reached the allowed minimum');
  require(_bet <= maxBet, 'rollDice: Your bet has exceeded the allowed maximum');
  require(getRealBalance() >= _bet * 6, 'rollDice: Not enough ballance in Dice contract');
  uint256 seed = uint256(keccak256(abi.encode(_userProvidedSeed, blockhash(block.number)))); // Hash user seed and blockhash
  bytes32 _requestId = requestRandomness(keyHash, _bet);
  RequestBet memory requestBet = RequestBet({
   bet: _bet,
   guessNumber: _guessNumber,
   realNumber: 0,
   win: 0
  });
  requestBets[_requestId] = requestBet;
  emit RequestRandomness(_requestId, keyHash, seed);
  return _requestId;
 }

 function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
  uint256 diceResult = randomness % 6 + 1;
  requestBets[requestId].realNumber = diceResult;
  emit RequestRandomnessFulfilled(requestId, randomness);
  uint256 _bet = requestBets[requestId].bet;
  uint256 fee = _bet * feePercent / 100;
  devBalance += fee;
  if (diceResult == requestBets[requestId].guessNumber) {
   uint256 win = (_bet - fee) * 6;
   balances[msg.sender] += win;
   totalBalances += win;
   requestBets[requestId].win = win;
   emit eventResult(true, win);
  } else {
   balances[msg.sender] -= _bet;
   totalBalances -= _bet;
   emit eventResult(false, _bet);
  }
 }

 function deposit(uint256 _amount) public {
  uint256 allowance = token.allowance(msg.sender, address(this));
  require(allowance >= _amount, 'deposit: Allowance is too low');
  require(_amount <= token.balanceOf(msg.sender), 'deposit: You cannot deposit more than your wallet balance');
  require(token.transferFrom(msg.sender, address(this), _amount));
  balances[msg.sender] += _amount;
  emit eventDeposit(_amount);
 }

 function withdraw(uint256 _amount) public {
  require(_amount <= balances[msg.sender], 'withdraw: You cannot withdraw more than your balance');
  require(token.transfer(msg.sender, _amount));
  balances[msg.sender] -= _amount;
  emit eventWithdraw(_amount);
 }

 function devWithdraw(uint256 _amount) public onlyOwner {
  require(_amount <= devBalance, 'devWithdraw: You cannot withdraw more than devBalance');
  require(token.transfer(devAddress, _amount));
  devBalance -= _amount;
  emit eventDevWithdraw(_amount);
 }

 function getRealBalance() public view returns (uint256) {
  return token.balanceOf(address(this));
 }

 function setDevAddress(address _devAddress) public onlyOwner {
  devAddress = _devAddress;
  emit eventSetDevAddress(_devAddress);
 }

 function setMinBet(uint256 _minBet) public onlyOwner {
  minBet = _minBet;
  emit eventSetMinBet(_minBet);
 }

 function setMaxBet(uint256 _maxBet) public onlyOwner {
  maxBet = _maxBet;
  emit eventSetMaxBet(_maxBet);
 }
}
