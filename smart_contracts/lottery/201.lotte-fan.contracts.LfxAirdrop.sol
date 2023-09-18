//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// We import this library to be able to use console.log
import 'hardhat/console.sol';

// This is the main building block for smart contracts.
contract LfxAirdrop {
  IERC20 public immutable token;

  bool public isWithdrawable;

  // the timestamp contract created
  uint public initTimestamp;

  // maximum total deposit amount
  uint public maxTotalSupply;
  // total LFX token has been depositted
  uint public totalSupply;

  // maximum number of participants
  uint public maxParticipant;
  // if this number reach to 0, the withdrawable will be enabled
  uint public participantCount;

  uint public minDepositAmount;
  uint public maxDepositAmount;

  // An address type variable is used to store ethereum accounts.
  address public owner;

  // store the balance of that the winner can withdraw
  // if after the draw, the winner does not withdraw, the balance will be added
  // so the winner can withdraw all the balance later
  // balanceOf[0] is the balance of the winner of the current round
  mapping(address => uint256) public balanceOf;

  event Airdrop(address indexed to, uint amount);

  constructor(
    address _token,
    uint _maxParticipant,
    uint _maxTotalSupply,
    uint _minDepositAmount,
    uint _maxDepositAmount
  ) {
    owner = msg.sender;
    initTimestamp = block.timestamp;
    isWithdrawable = false;

    token = IERC20(_token);
    maxParticipant = _maxParticipant;
    maxTotalSupply = _maxTotalSupply;
    minDepositAmount = _minDepositAmount;
    maxDepositAmount = _maxDepositAmount;
  }

  function _mint(address _to, uint _amount) private {
    totalSupply += _amount;
    balanceOf[_to] += _amount;
  }

  function _burn(address _from, uint _amount) private {
    totalSupply -= _amount;
    balanceOf[_from] -= _amount;
  }

  modifier isOwner() {
    require(msg.sender == owner, 'Lotte: caller is not the owner');
    _;
  }

  function setMaxParticipant(uint _maxParticipant) external isOwner {
    maxParticipant = _maxParticipant;
  }

  receive() external payable {
    require(
      isWithdrawable == false,
      'LfxAirdrop: The airdrop is already finished'
    );
    require(
      balanceOf[msg.sender] == 0,
      'LfxAirdrop: You have already deposited'
    );
    require(
      msg.value >= minDepositAmount && msg.value <= maxDepositAmount,
      'LfxAirdrop: Value must be in range'
    );

    _mint(msg.sender, msg.value);

    participantCount += 1;

    if (participantCount >= maxParticipant || totalSupply >= maxTotalSupply) {
      isWithdrawable = true;
    }
  }

  function withdraw() external {
    require(
      isWithdrawable == true,
      'LfxAirdrop: The airdrop is not finished yet'
    );
    require(
      balanceOf[msg.sender] > 0,
      'LfxAirdrop: You have no balance to withdraw'
    );

    uint balance = balanceOf[msg.sender];
    uint poolBalance = token.balanceOf(address(this));
    uint tokenAmount = (balance * poolBalance) / totalSupply;

    _burn(msg.sender, balance);
    // send airdrop token to the user
    token.transfer(msg.sender, tokenAmount);
    emit Airdrop(msg.sender, tokenAmount);

    // send ether back to the user
    address payable to = payable(msg.sender);
    to.transfer(balance);
  }

  function getInformation()
    external
    view
    returns (bool, uint, uint, uint, uint, uint, uint, uint, uint)
  {
    return (
      isWithdrawable,
      participantCount,
      totalSupply,
      token.balanceOf(address(this)),
      maxParticipant,
      maxTotalSupply,
      minDepositAmount,
      maxDepositAmount,
      initTimestamp
    );
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function burn(uint amount) external;

  event Transfer(address indexed from, address indexed to, uint amount);
  event Approval(address indexed owner, address indexed spender, uint amount);
}
