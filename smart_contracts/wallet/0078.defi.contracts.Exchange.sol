pragma solidity ^0.4.23;

import './lib/ERC20.sol';
import './lib/Ownable.sol';
import './lib/SafeMath.sol';

contract Exchange is Ownable {
  using SafeMath for uint256;

  address public feeAccount;
  uint256 public inactivityReleasePeriod;
  mapping (address => uint256) public invalidOrder;
  mapping (address => mapping (address => uint256)) public tokens;
  mapping (address => bool) public admins;
  mapping (address => uint256) public lastActiveTransaction;
  mapping (bytes32 => uint256) public orderFills;  
  mapping (bytes32 => bool) public traded;
  mapping (bytes32 => bool) public withdrawn;
  
  event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give);  
  event Deposit(address token, address user, uint256 amount, uint256 balance);
  event Withdraw(address token, address user, uint256 amount, uint256 balance);

  modifier onlyAdmin {
    require(msg.sender == owner || admins[msg.sender]);
    _;
  }

  constructor(address accountCollectingFees) public {
    owner = msg.sender;
    feeAccount = accountCollectingFees;
    inactivityReleasePeriod = 100000;
  }

  function invalidateOrdersBefore(address user, uint256 nonce) onlyAdmin public {
    require(nonce >= invalidOrder[user]);
    invalidOrder[user] = nonce;
  }
  
  function setInactivityReleasePeriod(uint256 expiry) onlyAdmin public returns (bool) {
    require(expiry <= 1000000);
    inactivityReleasePeriod = expiry;
    return true;
  }

  function setAdmin(address admin, bool isAdmin) onlyOwner public {
    admins[admin] = isAdmin;
  }

  function depositToken(address token, uint256 amount) public {
    tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
    lastActiveTransaction[msg.sender] = block.number;
    require(ERC20(token).transferFrom(msg.sender, this, amount));
    emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function deposit() payable public {
    tokens[address(0)][msg.sender] = tokens[address(0)][msg.sender].add(msg.value);
    lastActiveTransaction[msg.sender] = block.number;
    emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
  }

  function withdraw(address token, uint256 amount) public returns (bool) {
    require(block.number.sub(lastActiveTransaction[msg.sender]) >= inactivityReleasePeriod);
    require(tokens[token][msg.sender] >= amount);
    tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
    if (token == address(0)) {
      require(msg.sender.send(amount));
    } else {
      require(ERC20(token).transfer(msg.sender, amount));
    }
    emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
    return true;
  }

  function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) onlyAdmin public returns (bool) {
    bytes32 hash = keccak256(address(this), token, amount, user, nonce);
    require(!withdrawn[hash]);
    withdrawn[hash] = true;
    
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", hash), v, r, s) == user);
    
    //withdrawal fee will never be more than 1%
    if (feeWithdrawal > 10 finney) feeWithdrawal = 10 finney;
    
    require(tokens[token][user] >= amount);
    tokens[token][user] = tokens[token][user].sub(amount);
    tokens[token][feeAccount] = tokens[token][feeAccount].add(feeWithdrawal.mul(amount) / 1 ether);
    amount = (1 ether - feeWithdrawal).mul(amount) / 1 ether;
    if (token == address(0)) {
      require(user.send(amount));
    } else {
      require(ERC20(token).transfer(user, amount));
    }
    lastActiveTransaction[user] = block.number;
    emit Withdraw(token, user, amount, tokens[token][user]);
    return true;
  }

  function balanceOf(address token, address user) view public returns (uint256) {
    return tokens[token][user];
  }

  function trade(uint256[7] tradeValues, address[4] tradeAddresses, uint8[2] v, bytes32[4] rs) onlyAdmin public returns (bool) {
    require(invalidOrder[tradeAddresses[2]] <= tradeValues[2]);

    bytes32 orderHash0 = keccak256(address(this), tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeAddresses[2]);
    bytes32 orderHash = keccak256("\x19Ethereum Signed Message:\n32", orderHash0);
    require(ecrecover(orderHash, v[0], rs[0], rs[1]) == tradeAddresses[2]);

    bytes32 tradeHash0 = keccak256(orderHash0, tradeValues[3], tradeAddresses[3], tradeValues[4]); 
    bytes32 tradeHash = keccak256("\x19Ethereum Signed Message:\n32", tradeHash0);
    require(ecrecover(tradeHash, v[1], rs[2], rs[3]) == tradeAddresses[3]);

    require(!traded[tradeHash]);
    traded[tradeHash] = true;

    //market maker fee will never be more than 1%
    if (tradeValues[5] > 10 finney) tradeValues[5] = 10 finney;
    //market taker fee will never be more than 2%
    if (tradeValues[6] > 20 finney) tradeValues[6] = 20 finney;

    require(orderFills[orderHash].add(tradeValues[3]) <= tradeValues[0]);
    require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[3]);
    require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= (tradeValues[1].mul(tradeValues[3]) / tradeValues[0]));

    //TODO make sure all math operations are safe 
    
    tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[3]);
    tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].add(tradeValues[3].mul(((1 ether) - tradeValues[5])) / (1 ether));
    tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(tradeValues[3].mul(tradeValues[5]) / (1 ether));
    tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(tradeValues[1].mul(tradeValues[3]) / tradeValues[0]);
    tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].add(((1 ether) - tradeValues[6]).mul(tradeValues[1]).mul(tradeValues[3]) / tradeValues[0] / (1 ether));
    tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add((tradeValues[6]).mul(tradeValues[1]).mul(tradeValues[3]) / tradeValues[0] / (1 ether));
    
    orderFills[orderHash] = orderFills[orderHash].add(tradeValues[3]);
    
    lastActiveTransaction[tradeAddresses[2]] = block.number;
    lastActiveTransaction[tradeAddresses[3]] = block.number;

    //Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give);

    return true;
  }

}