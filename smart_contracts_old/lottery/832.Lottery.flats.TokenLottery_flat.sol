// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Utils/RevenueStream.sol

pragma solidity ^0.8.2;

contract RevenueStream {

  uint public fee;
  address public treasury;
  address public self = address(this);

  uint public fantomDebtToRecipient;
  mapping(IERC20 => uint) public TokenDebtToRecipient;

  uint public constant ftmDecimals = 1000000000000000000;

  function feeCalc(uint _total) internal view returns (uint) {
    uint _rake = (_total * fee) / ftmDecimals;
    return(_rake);
  }

  function takeFantomFee(uint _total) internal returns (uint) {
    uint rake = feeCalc(_total);
    fantomDebtToRecipient += rake;
    uint leftover = _total - rake;
    return leftover;
  }

  function takeTokenFee(IERC20 _tokenToTake, uint _total) internal returns (uint) {
    uint rake = feeCalc(_total);
    TokenDebtToRecipient[_tokenToTake] += rake;
    uint leftover = _total - rake;
    return leftover;
  }

  function withdrawToken(IERC20 ERC20Address) public returns (bool) {
    require(msg.sender == treasury, "You are not the fee recipient");
    require(TokenDebtToRecipient[ERC20Address] > 0, "you have nothing to claim");

    uint payment = TokenDebtToRecipient[ERC20Address];
    TokenDebtToRecipient[ERC20Address] = 0;
    ERC20Address.transfer(treasury, payment);

    return true;
  }

  function withdrawFantom() public returns (bool) {
    require(msg.sender == treasury, "You are not the fee recipient");
    require(fantomDebtToRecipient > 0, "you have nothing to claim");

    uint payment = fantomDebtToRecipient;
    fantomDebtToRecipient = 0;
    payable(msg.sender).transfer(payment);

    return true;
  }

  function viewFantomCollected() public view returns (uint) {
    return fantomDebtToRecipient;
  }

  function viewTokensCollected(IERC20 _token) public view returns (uint) {
    return TokenDebtToRecipient[_token];
  }
}

// File: contracts/Utils/UtilityPackage.sol

pragma solidity ^0.8.2;

contract UtilityPackage {

  address public sweeper;

  constructor() {
    sweeper = _sender();
  }

  function _sender() internal view returns (address) {
    return msg.sender;
  }

  function _timestamp() internal view returns (uint) {
    return block.timestamp;
  }

  function sweep(address tokenToSweep) public returns (bool) {
    require(_sender() == sweeper, "must be the sweeper");
    uint tokenBalance = IERC20(tokenToSweep).balanceOf(address(this));
    if (tokenBalance > 0) {
      IERC20(tokenToSweep).transfer(sweeper, tokenBalance);
    }
    return true;
  }

  function changeSweeper(address newSweeper) public returns (bool) {
    require(_sender() == sweeper, "Only the sweeper can assign a replacement");
    sweeper = newSweeper;
    return true;
  }

}

// File: contracts/Base/LotteryLogic.sol

struct Lottery {
  uint startTime;
  uint lastDraw;

  uint totalPot;

  bytes32 winningTicket;
  bool finished;
}

pragma solidity ^0.8.2;

contract BaseLottery is UtilityPackage {

  string public name;

  uint public frequency;
  uint public price;
  uint public odds;

  uint public currentLotto = 0;
  uint public currentDraw = 0;
  uint public ticketCounter = 0;

  uint public totalValuePlayed = 0;

  struct Ticket {
    address[] owners;
    uint ticketNumber;
  }

	mapping (uint => Lottery) lottos;
  mapping (bytes32 => Ticket) public tickets;
  mapping (uint => mapping(address => bytes32[])) public userTickets;
  mapping (address => uint) public debtToUser;

  event newRound(uint lottoNumber);
  event newEntry(address entrant, bytes32 ticketID, uint totalPot);
  event newDraw(bool winnerSelected, bytes32 winningTicket);
  event newPayment(address user, uint amount);

  function startNewRound() internal returns (bool) {
    currentLotto++;
    lottos[currentLotto] = Lottery(_timestamp(), _timestamp(), 0, bytes32(0), false);
    emit newRound(currentLotto);
    return true;
  }

  function resetGame() internal returns (bool) {
    currentDraw = 0;
    ticketCounter = 0;
    startNewRound();
    return true;
  }

  function selectWinningTicket() internal view returns (bytes32) {
    uint winningNumber = generateTicketNumber();
    bytes32 winningID = generateTicketID(winningNumber);

    if (tickets[winningID].owners.length > 0) {
      return winningID;
    } else {
      return bytes32(0);
    }
  }

  function createNewTicket() internal returns (bytes32) {
    uint ticketNumber = generateTicketNumber();
    bytes32 _ticketID = generateTicketID(ticketNumber);

    if (tickets[_ticketID].owners.length > 0) {
      tickets[_ticketID].owners.push(_sender());
      return _ticketID;
    } else {
      address[] memory newOwner = new address[](1);
      newOwner[0] = _sender();
      tickets[_ticketID] = Ticket(newOwner, ticketNumber);
      return _ticketID;
    }
  }

  function finalAccounting() internal returns (bool) {
    lottos[currentLotto].finished = true;
    assert(safeUserDebtCalculation());
    return true;
  }

  function safeUserDebtCalculation() internal returns (bool) {
    bytes32 winningTicket = lottos[currentLotto].winningTicket;
    uint winnings = lottos[currentLotto].totalPot;

    uint winnerCount = tickets[winningTicket].owners.length;
    uint winningsPerUser = (winnings / winnerCount);

    address[] memory winners = tickets[winningTicket].owners;

    for (uint i = 0; i < winners.length; i++) {
      debtToUser[winners[i]] += winningsPerUser;
    }
    return true;
  }

  function _safePay() internal returns (uint) {
    uint _winnings = debtToUser[_sender()];
    debtToUser[_sender()] = 0;
    return _winnings;
  }

  function _enter(uint _toPot) internal returns (bool) {
    ticketCounter++;
    totalValuePlayed += price;
    lottos[currentLotto].totalPot += _toPot;
    bytes32 ticketID = createNewTicket();
    userTickets[currentLotto][_sender()].push(ticketID);

    emit newEntry(_sender(), ticketID, lottos[currentLotto].totalPot);
    return true;
  }

  function _draw() internal returns (bool) {
    bytes32 _winner = selectWinningTicket();

    if (_winner == bytes32(0)) {
      currentDraw++;
      emit newDraw(false, _winner);
      return false;
    } else {
      lottos[currentLotto].winningTicket = _winner;
      finalAccounting();
      resetGame();
      emit newDraw(true, _winner);
      return true;
    }
  }

  function generateTicketNumber() internal view returns (uint) {
    uint _rando = generateRandomNumber();
    uint _ticketNumber = _rando % odds;
    return _ticketNumber;
  }

  function generateTicketID(uint _ticketNumber) internal view returns (bytes32) {
    bytes32 _ticketID = keccak256(abi.encodePacked(currentLotto, currentDraw, _ticketNumber));
    return _ticketID;
  }

  function generateRandomNumber() internal view returns (uint) {
    return (uint(keccak256(abi.encodePacked(block.timestamp, block.number, ticketCounter))));
  }
}

// File: contracts/Interfaces/ITokenLottery.sol

pragma solidity ^0.8.2;

interface ITokenLottery {
  function draw() external returns (bool);
  function enter() external returns (bool);
  function getPaid() external returns (bool);

  function viewTokenAddress() external view returns (address);
  function viewName() external view returns (string memory);
  function viewFrequency() external view returns (uint);
  function viewPrice() external view returns (uint);
  function viewWinChance() external view returns (uint);
  function viewCurrentLottery() external view returns (uint);
  function viewTicketHolders(bytes32 ticketID) external view returns (address[] memory);
  function viewTicketNumber(bytes32 ticketID) external view returns (uint);
  function viewStartTime(uint lottoNumber) external view returns (uint);
  function viewLastDrawTime(uint lottoNumber) external view returns (uint);
  function viewTotalPot(uint lottoNumber) external view returns (uint);
  function viewWinningTicket(uint lottoNumber) external view returns (bytes32);
  function viewUserTicketList(uint lottoNumber) external view returns (bytes32[] memory);
  function viewWinnings() external view returns (uint);

  function readyToDraw() external view returns (bool);
}

// File: contracts/TokenLottery.sol

pragma solidity ^0.8.2;

contract TokenLottery is ITokenLottery, BaseLottery, RevenueStream {

  IERC20 public inputToken;

  constructor(string memory _name, uint _frequency, uint _price, uint _odds, IERC20 _inputToken, uint _fee, address _treasury) {
    name = _name;
    frequency = _frequency;
    price = _price;
    odds = _odds;
    fee = _fee;
    treasury = _treasury;
    inputToken = _inputToken;
    startNewRound();
  }

  function enter() public override returns (bool) {
    require (inputToken.balanceOf(_sender()) >= price, "not enough tokens to enter");

    uint toPot = beforeEachEnter();
    _enter(toPot);

    return true;
  }

  function draw() public override returns (bool) {
    require (readyToDraw(), "not enough time has elapsed since last draw");

    beforeEachDraw();
    _draw();

    return true;
  }

  function getPaid() public override returns (bool) {
    require(debtToUser[_sender()] != 0, "you are not owed any money");

    beforeEachPayment();
    uint winnings = _safePay();
    IERC20(inputToken).transfer(_sender(), winnings);

    emit newPayment(_sender(), winnings);
    return true;
  }

  function beforeEachEnter() internal returns (uint) {
    uint amountAfterFee = takeTokenFee(inputToken, price);
    IERC20(inputToken).transferFrom(_sender(), address(this), price);
    return amountAfterFee;
  }

  function beforeEachDraw() internal returns (bool) {
    lottos[currentLotto].lastDraw = _timestamp();
    return true;
  }

  function beforeEachPayment() internal returns (bool) { }

  function viewTokenAddress() public view override returns (address) {
    return address(inputToken);
  }

  function viewName() public view override returns (string memory) {
    return name;
  }

  function viewFrequency() public view override returns (uint) {
    return frequency;
  }

  function viewPrice() public view override returns (uint) {
    return price;
  }

  function viewWinChance() public view override returns (uint) {
    return (odds);
  }

  function viewCurrentLottery() public view override returns (uint) {
    return currentLotto;
  }

  function viewTicketHolders(bytes32 ticketID) public view override returns (address[] memory) {
    return tickets[ticketID].owners;
  }

  function viewTicketNumber(bytes32 ticketID) public view override returns (uint) {
    return tickets[ticketID].ticketNumber;
  }

  function viewStartTime(uint lottoNumber) public view override returns (uint) {
    return lottos[lottoNumber].startTime;
  }

  function viewLastDrawTime(uint lottoNumber) public view override returns (uint) {
    return lottos[lottoNumber].lastDraw;
  }

  function viewTotalPot(uint lottoNumber) public view override returns (uint) {
    return lottos[lottoNumber].totalPot;
  }

  function viewWinningTicket(uint lottoNumber) public view override returns (bytes32) {
    return lottos[lottoNumber].winningTicket;
  }

  function viewUserTicketList(uint lottoNumber) public view override returns (bytes32[] memory) {
    return userTickets[lottoNumber][msg.sender];
  }

  function viewWinnings() public view override returns (uint) {
    return debtToUser[_sender()];
  }

  function readyToDraw() public view override returns (bool) {
    return (_timestamp() - lottos[currentLotto].lastDraw >= frequency);
  }
}
