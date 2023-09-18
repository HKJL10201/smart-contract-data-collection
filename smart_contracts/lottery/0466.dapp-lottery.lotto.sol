
pragma solidity 0.4.25;

import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
contract SafeMath {
/**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
  */
  constructor() public {
    owner = msg.sender;
  }

  /**
    * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "sender is not owner");
    _;
  }

  /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "newOwner addres is zero");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract lottery is Ownable, usingOraclize, SafeMath {


  /*
    * checks only Drawer address is calling
  */
  modifier onlyDrawer() {
    require(msg.sender == drawerAddress || msg.sender == owner, "sender is not drawerAddress");
    _;
  }

  /*
    * checks address is zero or not.
  */
  modifier isAddressZero {
    require(msg.sender != address(0), "new address is zero");
    _;
  }


  struct Game {
    uint endTime;
    uint ticketPrice;
    uint accumJackpotAmounts;
    bytes winningNumbers;
    bytes32 queryId;
    Ticket[] tickets;
    string hashString;
    mapping (byte => bool) winNumMapping;
    mapping (address => uint) playerTicketCount;
    mapping (uint => uint) winPlayersCount;
    mapping (uint => bool) winners;
  }

  struct Ticket {
    uint256 time;
    address player;
    bytes   numbers;
  }

  address public adminAddress;
  address public drawerAddress;
  address public feeAddress;
  bool public gameStatus;
  uint public adminFee;
  uint public gameNumber;
  uint public numbersStart;
  uint public numbersCount;
  uint public numbersCountMax;
  uint public ticketPrice;

  uint public prizeStart;
  uint public prizeNumCount;

  uint[] public winPercent;

  uint public orclizeGasPrice;

  mapping (uint => Game) public games;

  // For Players Event
  event LogBuyTicket(uint _time, address _player, bytes _numbers, uint _count, uint _ticketTotalCount);
  // For Owner Event
  event LogEndGameBegin(bool _success);
  event LogEndGameSuccess(bool _success);
  event LogEndGameFail(bool _success);
  event LogStartNewGame(bool _start, uint _gameNumber, bytes _winNumbers);

  constructor() public payable {
    
    // sets the Ledger authenticity proof in the constructor
    oraclize_setProof(proofType_Ledger);

    // Lottery numbers range ( numbersStart <= gameNumbers <= numbersCountMax)
    numbersStart = 1;
    numbersCount = 5;
    numbersCountMax = 25;
    ticketPrice = .01 ether;
    winPercent = [0, 0, 0, 20, 20, 60];
    prizeStart = 3;   //winPercent Index start
    prizeNumCount = 3;

    // operator`s fee 10%
    adminAddress = msg.sender;
    drawerAddress = 0xd36C57086c9fC2d06C3009207F0d4D818CAc4F63;
    feeAddress = 0x798F4A40dc6C45a812f1549402E3D9E5BA5fc9a5;
    adminFee = 10;
    gameStatus = true;
    games[gameNumber].ticketPrice = ticketPrice;

    // oraclize paramaters
    orclizeGasPrice = 400000;

  }

  /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

  function setAdminAddress(address _admin) public onlyOwner isAddressZero {
    adminAddress = _admin;
  }

  function setDrawerAddress(address _drawer) public onlyOwner isAddressZero {
    drawerAddress = _drawer;
  }

  function setFeeAddress(address _feeAddr) public onlyOwner isAddressZero {
    feeAddress = _feeAddr;
  }

  function setAdminFee(uint _fee) public onlyOwner isAddressZero {
    require(_fee >= 0, "Fee is under 0");
    adminFee = _fee;
  }

  function setTicketPrice(uint _price) public onlyOwner isAddressZero {
    require(_price >= 0, "Price is under 0");
    ticketPrice = _price;
  }

  function kill() public onlyOwner isAddressZero {
    selfdestruct(owner);
  }


  function startGame(uint _carryOverJackpot, uint[] _totalWinCount) external onlyDrawer {

    // Set game win players count.
    for(uint i = prizeStart; i < numbersCount + 1; i++) {
      if(0 < _totalWinCount[i]) {
        games[gameNumber].winPlayersCount[i] = _totalWinCount[i];
      }
    }

    // Start New Game.
    gameNumber++;
    games[gameNumber].ticketPrice = ticketPrice;
    games[gameNumber].accumJackpotAmounts = _carryOverJackpot;
    gameStatus = true;

    emit LogStartNewGame(gameStatus, gameNumber-1, games[gameNumber-1].winningNumbers);

  }

  function endGame() external onlyDrawer {
    gameStatus = false;

    uint numberOfBytes = 28; // number of random bytes we want the datasource to return
    uint delay = 0; // number of seconds to wait before the execution takes place
    uint callbackGas = orclizeGasPrice; // amount of gas we want Oraclize to set for the callback function

    // this function internally generates the correct oraclize_query and returns its queryId
    games[gameNumber].queryId = oraclize_newRandomDSQuery(delay, numberOfBytes, callbackGas);

    emit LogEndGameBegin(true);
  }

  function buyTicket(bytes _ticketNumber, uint _ticketCount) external payable {

    require(gameStatus, "game is processing sth");
    require(_ticketCount > 0, "ticket count should be not under 0");
    require(msg.value == mul(ticketPrice, _ticketCount), "ticket price is not equal");
    require(_ticketNumber.length == mul(numbersCount, _ticketCount), "ticket number`s length is not match");

    bytes memory pickNumbers = new bytes(numbersCount);

    for(uint i = 0; i < _ticketCount; i++) {
      for(uint j = 0; j < numbersCount; j++) {
        pickNumbers[j] = _ticketNumber[j + (numbersCount * i)];
        require(checkPickNumbers(pickNumbers[j]), "player`s pick number is wrong");
      }

      require(checkDuplicates(pickNumbers), "Lottery Numbers are duplicated");

      games[gameNumber].tickets.push(Ticket(block.timestamp, msg.sender, pickNumbers));
      games[gameNumber].playerTicketCount[msg.sender]++;

    }

    emit LogBuyTicket(block.timestamp, msg.sender, _ticketNumber, _ticketCount, games[gameNumber].tickets.length);

  }

  function getGameHistory(uint _gameNumber) external view 
    returns (
      uint endTime,
      uint accumJackpot,
      uint ticketCount,
      uint adminFee,
      uint[] winningPercent,
      uint[] winPlayersCount,
      uint[] winNumbers
  ) {
    require(0 <= _gameNumber && _gameNumber <= gameNumber, "game number is error");
    Ticket[] memory tickets = games[_gameNumber].tickets;
    winNumbers = new uint[](numbersCount);
    winningPercent = new uint[](numbersCount + 1);
    winPlayersCount = new uint[](numbersCount + 1);

    uint numbersIndex;

    // save endtime and jackpot.
    endTime = games[_gameNumber].endTime;
    ticketCount = tickets.length;
    winningPercent = winPercent;
    accumJackpot = games[_gameNumber].accumJackpotAmounts;
    adminFee = adminFee;

    // save game win numbers.
    for(uint i = 1; i < numbersCountMax + 1; i++) {
      if(games[_gameNumber].winNumMapping[byte(i)]) {
        winNumbers[numbersIndex++] = i;
      }
    }

    // save game winners
    for(i = prizeStart; i < numbersCount + 1; i++) {
      winPlayersCount[i] = games[_gameNumber].winPlayersCount[i];
    }
  }

  function getPlayerAllTickets(address _player, uint _start, uint _end) external view 
    returns (
      uint[] winNumbers,
      uint[] myTickets
    )
  {
    require(_player != address(0),"address should be not 0");
    winNumbers = new uint[]((_end - _start) * numbersCount);
    uint winNumbersIndex;
    uint playerTicketIndex;
    uint playerTicketCount;

    // get all game win numbers.
    for(uint i = _start; i < _end; i++) {
      playerTicketCount += games[i].playerTicketCount[_player];
      for(uint j = 1; j < numbersCountMax + 1; j++) {
        if(games[i].winNumMapping[byte(j)]) {
          winNumbers[winNumbersIndex++] = j;
        }
      }
    }

    // get all player tickets.
    // numbersCount + 1 for gameNumber
    myTickets = new uint[](playerTicketCount * (numbersCount + 1));
    for(i = _start; i < _end; i++) {
      for(j = 0; j < games[i].tickets.length; j++) {
        if(games[i].tickets[j].player == _player) {
          // set Game Number
          myTickets[playerTicketIndex++] = i;
          // set Player Numbers
          for(uint k = 0; k < numbersCount; k++) {
            myTickets[playerTicketIndex++] = uint(games[i].tickets[j].numbers[k]);
          }
        }
      }
    }
  }

  function getPlayerTickets(address _player, uint _gameNumber) external view 
    returns (
      uint[] time, 
      uint[] numbers
    ) 
  {
    require(_player != address(0),"address should be not 0");
    require(0 <= _gameNumber && _gameNumber <= gameNumber, "game number is error");

    Ticket[] memory tickets = games[_gameNumber].tickets;
    numbers = new uint[](games[_gameNumber].playerTicketCount[_player] * numbersCount);
    time = new uint[](games[_gameNumber].playerTicketCount[_player]);
    
    uint timeIndex;
    uint numbersIndex;

    for(uint i = 0; i < tickets.length; i++) {
      if(tickets[i].player == _player) {
        time[timeIndex++] = tickets[i].time;
        for(uint k = 0; k < numbersCount; k++) {
          numbers[numbersIndex++] = uint(tickets[i].numbers[k]);
        }
      }
    }
  }

  function getGameWinners(uint _gameNumber) 
    external 
    view 
    returns (
      address[] player,
      uint[] time, 
      uint[] numbers
    ) 
  {
    require(0 <= _gameNumber && _gameNumber <= gameNumber, "game number is error");
    
    uint length;
    for(uint i = prizeStart; i < numbersCount + 1; i++){
      length += games[_gameNumber].winPlayersCount[i];
    }

    Ticket[] memory tickets = games[_gameNumber].tickets;

    player = new address[](length);
    time = new uint[](length);
    numbers = new uint[](length * numbersCount);

    uint index;
    uint numbersIndex;
    for(i = 0; i < tickets.length; i++) {
      if(games[_gameNumber].winners[i]) {
        player[index] = tickets[i].player;
        time[index++] = tickets[i].time;
        for(uint k = 0; k < numbersCount; k++) {
          numbers[numbersIndex++] = uint(tickets[i].numbers[k]);
        }
      }
    }
  }

  function getGameDetails(uint _gameNumber) external view 
    returns (
      uint endTime,
      uint ticketPrice,
      uint ticketCount,
      uint accumJackpot,
      uint[] gameReward,
      uint[] numbers
    ) 
  {

    require(_gameNumber >= 0, "Game Number should be over 0");
    numbers = new uint[](numbersCount);
    gameReward = new uint[](numbersCount + 1);

    uint index;

    endTime = games[_gameNumber].endTime;
    ticketPrice = games[_gameNumber].ticketPrice;
    ticketCount = games[_gameNumber].tickets.length;
    accumJackpot = games[_gameNumber].accumJackpotAmounts;
    gameReward = winPercent;

    for(uint i = 1; i < numbersCountMax + 1; i++) {
      if(games[_gameNumber].winNumMapping[byte(i)]) {
        numbers[index++] = i;
      }
    }
  }


  function __callback(bytes32 _queryId, string _result, bytes _proof) public
  {
    require(msg.sender == oraclize_cbAddress(), "Should be eqaul to request");

    if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) == 0) {
      if(games[gameNumber].queryId == _queryId) {
        games[gameNumber].endTime = block.timestamp;
        uint jackpot = (games[gameNumber].tickets.length * games[gameNumber].ticketPrice);// + games[gameNumber].accumJackpotAmounts;

        // send ethereum for operation cost.
        if(jackpot > 0) {
          feeAddress.transfer((jackpot * adminFee) / 100);
        }
        games[gameNumber].hashString = _result;
        games[gameNumber].winningNumbers = generateRandom(games[gameNumber].hashString, numbersCount, numbersCountMax);
        for (uint i = 0; i < games[gameNumber].winningNumbers.length; i++) {
          games[gameNumber].winNumMapping[games[gameNumber].winningNumbers[i]] = true;
        }
    
        emit LogEndGameSuccess(true);
      }
    }
    else {
      emit LogEndGameFail(false);
    }
  }

  function getGameDrawInfos() external view 
    returns (
      uint carryOverJackpot,
      uint totalTicketCount,
      uint totalWinPlayersCount,
      uint[] totalWinCount,
      uint[] playersAmounts
    ) 
  {

    uint jackpotAmounts = (games[gameNumber].tickets.length * games[gameNumber].ticketPrice) + games[gameNumber].accumJackpotAmounts;
    jackpotAmounts -= ((games[gameNumber].tickets.length * games[gameNumber].ticketPrice) * adminFee) / 100;

    totalWinCount = new uint[](numbersCount + 1);
    playersAmounts = new uint[](numbersCount + 1);
    uint winNumberCount;
    uint sendedJackpotAmounts;

    // 1. pick win players.
    for(uint i = 0; i < games[gameNumber].tickets.length; i++) {

      for (uint k = 0; k < games[gameNumber].winningNumbers.length; k++) {

        if( games[gameNumber].winNumMapping[byte(games[gameNumber].tickets[i].numbers[k])] ) {
          winNumberCount++;
        }
      }

      // 2. Win players counting.
      if(prizeStart <= winNumberCount) {
        totalWinCount[winNumberCount]++;
        totalWinPlayersCount++;
      }

      winNumberCount = 0;
    }

    // 3. calculate winners prizes.
    for(i = prizeStart; i < numbersCount + 1; i++) {
      if(0 < totalWinCount[i]) {
        playersAmounts[i] = (jackpotAmounts * winPercent[i] / 100) / totalWinCount[i];
        sendedJackpotAmounts += (jackpotAmounts * winPercent[i] / 100);
      }
    }

    // 4. Set to carry over jackpot amounts.
    carryOverJackpot = jackpotAmounts - sendedJackpotAmounts;

    // 5. Set Total Ticket Count.
    totalTicketCount = games[gameNumber].tickets.length;

  }

  function getWinners(uint _start, uint _end) external view 
    returns (
      uint[] index,
      uint[] winCount
    ) 
  {
    uint ticketIndex;
    uint winNumberCount;
    index = new uint[](getWinnersCount(_start, _end));
    winCount = new uint[](getWinnersCount(_start, _end));

    for(uint i = _start; i < _end; i++) {

      // find winners
      for (uint k = 0; k < games[gameNumber].winningNumbers.length; k++) {
        if(games[gameNumber].winNumMapping[byte(games[gameNumber].tickets[i].numbers[k])]) {
          winNumberCount++;
        }
      }

      // set winners
      if(prizeStart <= winNumberCount) {
        index[ticketIndex] = i;
        winCount[ticketIndex++] = winNumberCount;
      }
      winNumberCount = 0;
    }

  }


  function () public payable {

  }

  function sendRewardToPlayers(uint[] _winnerIndex, uint[] _winReward) external onlyDrawer {
    require(_winnerIndex.length > 0, "winner index is empty");
    require(_winReward.length > 0, "win numbers count is empty");

    for(uint i = 0; i < _winnerIndex.length; i++) {
      games[gameNumber].winners[_winnerIndex[i]] = true;
      games[gameNumber].tickets[_winnerIndex[i]].player.transfer(_winReward[i]);
    }

  }

  function generateRandom(string _stringHash, uint numbersCount, uint numbersCountMax) 
    internal
    pure 
    returns (
      bytes
    ) 
  {
    bytes32 random = keccak256(_stringHash);
    bytes memory allNumbers = new bytes(numbersCountMax);
    bytes memory winNumbers = new bytes(numbersCount);

    for (uint i = 0; i < numbersCountMax; i++) {
      allNumbers[i] = byte(i + 1);
    }

    for (i = 0; i < numbersCount; i++) {
      uint n = numbersCountMax - i;
      uint r = (uint(random[i * 4]) + (uint(random[i * 4 + 1]) << 8) + (uint(random[i * 4 + 2]) << 16) + (uint(random[i * 4 + 3]) << 24)) % n;
      winNumbers[i] = allNumbers[r];
      allNumbers[r] = allNumbers[n - 1];
    }

    return winNumbers;
  }


  function getWinnersCount(uint _start, uint _end) internal view returns (uint ret) 
  {
    uint winNumberCount;

    for(uint i = _start; i < _end; i++) {

      // find winners
      for (uint k = 0; k < games[gameNumber].winningNumbers.length; k++) {
        if(games[gameNumber].winNumMapping[byte(games[gameNumber].tickets[i].numbers[k])]) {
          winNumberCount++;
        }
      }

      // increase winner players count
      if(prizeStart <= winNumberCount) {
        ret++;
      }
      winNumberCount = 0;
    }
  }

  function checkPickNumbers(byte _number) internal returns (bool) {

    if(numbersStart <= uint(_number) && uint(_number) <= numbersCountMax) {
      return true;
    } else {
      return false;
    }

  }

  function checkDuplicates(bytes _array) internal pure returns (bool) {
    for (uint i = 0; i < _array.length - 1; i++) {
      for (uint j = i + 1; j < _array.length; j++) {
        if (_array[i] == _array[j]) return false;
      }
    }
    return true;
  }

}
