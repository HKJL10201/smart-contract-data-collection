//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// We import this library to be able to use console.log
import 'hardhat/console.sol';

// This is the main building block for smart contracts.
contract Lotte {
  struct Ticket {
    // the owner of the ticket
    address owner;
    // ticket: [00, 23]-[00, 59], it will be 1440 different tickets, e.g.
    // 0023, 0159, 0012, 0000, 0001, 0002, 0003, 0004, 0005, 0006
    // ticket will be converted to uint, e.g. 0023 -> 23, 0159 -> 159
    uint ticket;
  }

  struct Draw {
    uint timestamp;
    address actor;
    uint winningNumber;
    uint winningAmount;
    uint winnerCount;
    address[] winnerList;
  }

  // An address type variable is used to store ethereum accounts.
  address public owner;

  // Address to store pot balance
  address private immutable potAddress = address(0);

  IERC20 public immutable token;
  address public immutable vaultAddress;

  uint public round;
  uint public lastDrawTimestamp;

  // 100 LFX per ticket
  uint public ticketPrice;

  // the minimum duration between 2 draws
  uint public minDrawDuration;

  // total amount of token that users have purchased
  uint public totalTicket;
  // total token in the contract
  uint public totalSupply;

  // the system fee rate, 4.0% of the ticket
  uint public systemFeeRate = 400;
  // the draw fee rate, 5.0% of system fees
  uint public drawFeeRate = 500;
  // the burn rate, 1.0% of system fees
  uint public burnRate = 100;

  // rate for the referrer, 1.2% of the ticket
  uint public refRateLayer1 = 120;
  // rate for the referrer, 0.55% of the ticket
  uint public refRateLayer2 = 55;
  // rate for the referrer, 0.25% of the ticket
  uint public refRateLayer3 = 25;

  // store who is the referrer of the user
  mapping(address => address) public ref;

  // store ticket data
  mapping(uint256 => Ticket) ticketData;

  // store historical data
  mapping(uint => Draw) public drawData;

  // store the balance of that the winner can withdraw
  // if after the draw, the winner does not withdraw, the balance will be added
  // so the winner can withdraw all the balance later
  // balanceOf[0] is the balance of the winner of the current round
  mapping(address => uint256) public balanceOf;

  // The Transfer event helps off-chain aplications understand
  // what happens within your contract.
  event EvtPurchase(address indexed _from, uint[] tickets);

  event EvtDraw(address indexed _from, Draw draw);

  constructor(
    address _token,
    address _vaultAddress,
    uint _ticketPrice,
    uint _minDrawDuration,
    uint _systemFeeRate,
    uint _drawFeeRate,
    uint _burnRate,
    uint _refRateLayer1,
    uint _refRateLayer2,
    uint _refRateLayer3
  ) {
    owner = msg.sender;
    lastDrawTimestamp = block.timestamp;
    round = 0;

    token = IERC20(_token);
    vaultAddress = _vaultAddress;
    ticketPrice = _ticketPrice;
    minDrawDuration = _minDrawDuration;

    systemFeeRate = _systemFeeRate;
    drawFeeRate = _drawFeeRate;
    burnRate = _burnRate;
    refRateLayer1 = _refRateLayer1;
    refRateLayer2 = _refRateLayer2;
    refRateLayer3 = _refRateLayer3;
  }

  function _mint(address _to, uint _amount) private {
    totalSupply += _amount;
    balanceOf[_to] += _amount;
  }

  function _burn(address _from, uint _amount) private {
    totalSupply -= _amount;
    balanceOf[_from] -= _amount;
  }

  function _resetAndStartNewRound() private {
    totalTicket = 0;
    round++;
    lastDrawTimestamp = block.timestamp;
  }

  function _isAddress(address _a) private pure returns (bool) {
    return _a != address(0);
  }

  function _transfer(address to, uint amount) private {
    require(to != address(0), 'Lotte: address should not be zero');
    _burn(to, amount);
    token.transfer(to, amount);
  }

  function _burnSomeOfSystemFees(uint systemFees) private {
    uint burnAmount = (systemFees * burnRate) / 10000;
    _burn(vaultAddress, burnAmount);
    // burn 0.5% of the total system fees
    token.burn(burnAmount);
  }

  function _withdrawAllToVault() private {
    uint amount = balanceOf[vaultAddress];
    _transfer(vaultAddress, amount);
  }

  modifier isOwner() {
    require(msg.sender == owner, 'Lotte: caller is not the owner');
    _;
  }

  function setTicketPrice(uint _ticketPrice) external isOwner {
    ticketPrice = _ticketPrice;
  }

  function setMinDrawDuration(uint _minDrawDuration) external isOwner {
    minDrawDuration = _minDrawDuration;
  }

  function setSystemFeeRate(uint _systemFeeRate) external isOwner {
    systemFeeRate = _systemFeeRate;
  }

  function setDrawFeeRate(uint _drawFeeRate) external isOwner {
    drawFeeRate = _drawFeeRate;
  }

  function setBurnRate(uint _burnRate) external isOwner {
    burnRate = _burnRate;
  }

  function setRefRateLayer1(uint _refRateLayer1) external isOwner {
    refRateLayer1 = _refRateLayer1;
  }

  function setRefRateLayer2(uint _refRateLayer2) external isOwner {
    refRateLayer2 = _refRateLayer2;
  }

  function setRefRateLayer3(uint _refRateLayer3) external isOwner {
    refRateLayer3 = _refRateLayer3;
  }

  function getAmountOfTicketByTicketNumber(
    uint ticketNumber
  ) public view returns (uint) {
    uint count;

    for (uint i; i < totalTicket; i++) {
      if (
        ticketData[i].ticket == ticketNumber &&
        ticketData[i].owner != address(0)
      ) {
        count++;
      }
    }

    return count;
  }

  function _distributeRewardByTicketNumber(
    uint ticketNumber,
    uint amount
  ) private {
    for (uint i; i < totalTicket; i++) {
      if (
        ticketData[i].ticket == ticketNumber &&
        ticketData[i].owner != address(0)
      ) {
        drawData[round].winnerList.push(ticketData[i].owner);
        _mint(ticketData[i].owner, amount);
      }
    }
  }

  // create a number that return random number in range [0, 1439]
  function getRandom() public view virtual returns (uint) {
    return
      (uint(
        keccak256(
          abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)
        )
      ) % 1141) - 1;
  }

  function purchase(uint[] calldata _tickets, address refAddress) external {
    require(_tickets.length > 0, 'Lotte: ticket cannot be empty');
    require(_tickets.length <= 7, 'Lotte: ticket cannot be more than 7');
    require(refAddress != msg.sender, 'Lotte: referrer cannot be yourself');

    uint _amount = ticketPrice * _tickets.length;
    uint amount = _amount;

    // assign the ref address to the sender
    if (ref[msg.sender] == address(0) && refAddress != address(0)) {
      ref[msg.sender] = refAddress;
    }

    // calculate ref fees for users
    address refAddLayer1 = ref[msg.sender];
    address refAddLayer2 = ref[refAddLayer1];
    address refAddLayer3 = ref[refAddLayer2];

    // log system fee into balance of vault address
    // calculate system fees then assigned it to the vault
    uint fee = (_amount * systemFeeRate) / 10000;
    amount -= fee;
    _mint(vaultAddress, fee);

    if (_isAddress(refAddLayer1)) {
      uint refFee1 = (_amount * refRateLayer1) / 10000;
      amount -= refFee1;
      _mint(refAddLayer1, refFee1);
    }
    if (_isAddress(refAddLayer2)) {
      uint refFee2 = (_amount * refRateLayer2) / 10000;
      amount -= refFee2;
      _mint(refAddLayer2, refFee2);
    }
    if (_isAddress(refAddLayer3)) {
      uint refFee3 = (_amount * refRateLayer3) / 10000;
      amount -= refFee3;
      _mint(refAddLayer3, refFee3);
    }

    _mint(potAddress, amount);

    for (uint i; i < _tickets.length; i++) {
      uint _ticket = _tickets[i];
      ticketData[totalTicket + i] = Ticket({
        owner: msg.sender,
        ticket: _ticket
      });
    }
    totalTicket += _tickets.length;

    // take the money
    token.transferFrom(msg.sender, address(this), _amount);

    emit EvtPurchase(msg.sender, _tickets);
  }

  function draw() external {
    require(
      block.timestamp - lastDrawTimestamp >= minDrawDuration,
      'Lotte: not enough time to draw'
    );
    require(totalTicket > 7, 'Lotte: total ticket should be more than 7');

    // calculate the winner then update available balance to their account
    uint winningNumber = this.getRandom();
    uint winnerCount = this.getAmountOfTicketByTicketNumber(winningNumber);

    drawData[round].winningNumber = winningNumber;
    drawData[round].timestamp = block.timestamp;
    drawData[round].actor = msg.sender;

    // found the winner, so then distribute the pot rewards
    if (winnerCount > 0) {
      uint totalPot = balanceOf[potAddress];
      uint winningAmount = totalPot / winnerCount;

      drawData[round].winnerCount = winnerCount;
      drawData[round].winningAmount = winningAmount;

      _burn(potAddress, totalPot);
      _distributeRewardByTicketNumber(winningNumber, winningAmount);
    }

    // rewards 5% of the system fees for whom took the action
    uint systemFees = balanceOf[vaultAddress];
    uint reward = (systemFees * drawFeeRate) / 10000;
    _burn(vaultAddress, reward);
    _mint(msg.sender, reward);

    // burn 5% of system fees
    _burnSomeOfSystemFees(systemFees);
    // the revenue will be send to the vault immediately
    // so the investors can withdraw it anytime
    _withdrawAllToVault();

    // emit the event
    emit EvtDraw(msg.sender, drawData[round]);

    // reset the round
    _resetAndStartNewRound();
  }

  function withdraw(uint256 amount) external {
    require(balanceOf[msg.sender] >= amount, 'Lotte: not enough balance');
    _transfer(msg.sender, amount);
  }

  function getTotalPot() public view returns (uint) {
    return balanceOf[potAddress];
  }

  function getAddressListByTicketNumber(
    uint ticketNumber
  ) public view returns (address[] memory) {
    address[] memory addresses = new address[](totalTicket);
    uint count;

    for (uint i; i < totalTicket; i++) {
      if (
        ticketData[i].ticket == ticketNumber &&
        ticketData[i].owner != address(0)
      ) {
        addresses[count] = ticketData[i].owner;
        count++;
      }
    }

    address[] memory result = new address[](count);
    for (uint i; i < count; i++) {
      result[i] = addresses[i];
    }

    return result;
  }

  function getLastDraw() public view returns (Draw memory) {
    if (round == 0) {
      return Draw(0, address(0), 0, 0, 0, new address[](0));
    }

    return drawData[round - 1];
  }

  function getTicketListByAddress(
    address _address
  ) public view returns (uint[] memory) {
    uint[] memory tickets = new uint[](totalTicket);
    uint count;

    for (uint i; i < totalTicket; i++) {
      if (ticketData[i].owner == _address) {
        tickets[count] = ticketData[i].ticket;
        count++;
      }
    }

    uint[] memory result = new uint[](count);
    for (uint i; i < count; i++) {
      result[i] = tickets[i];
    }

    return result;
  }

  function getInformation()
    public
    view
    returns (uint, uint, bool, uint, uint, uint, uint, uint, uint)
  {
    uint totalPot = balanceOf[potAddress];
    uint systemFees = balanceOf[vaultAddress];
    uint drawFees = (systemFees * drawFeeRate) / 10000;
    uint burnAmount = (systemFees * burnRate) / 10000;
    bool isDrawable = (block.timestamp - lastDrawTimestamp >=
      minDrawDuration) && (totalTicket > 7);

    return (
      lastDrawTimestamp,
      round,
      isDrawable,
      totalTicket,
      totalSupply,
      totalPot,
      systemFees,
      drawFees,
      burnAmount
    );
  }

  function getConfig()
    public
    view
    returns (uint, uint, uint, uint, uint, uint, uint, uint)
  {
    return (
      ticketPrice,
      systemFeeRate,
      drawFeeRate,
      burnRate,
      refRateLayer1,
      refRateLayer2,
      refRateLayer3,
      minDrawDuration
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
