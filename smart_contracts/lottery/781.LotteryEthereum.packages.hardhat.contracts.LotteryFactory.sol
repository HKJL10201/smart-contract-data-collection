pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import 'hardhat/console.sol';
import './LotteryHelper.sol';
import './LottyToken.sol';
import './interfaces/IRandomNumberGenerator.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

contract LotteryFactory is LotteryHelper, Ownable {
  using SafeMath for uint256;

  address public LTY;
  LottyToken ILottyToken;
  uint256 public lotteryCount;
  uint256 public ticketPrice = 0.005 ether;
  uint256 claimableBalance = 0;
  uint256 devFeeBalance = 0;
  uint256 stakingBalance = 0;
  uint256 burnBalance = 0;
  IRandomNumberGenerator public randomGenerator;

  enum TicketStatus {
    Pending,
    Lost,
    TwoWinningNumber,
    ThreeWinningNumber,
    FourWinningNumber,
    FiveWinningNumber
  }

  struct Ticket {
    uint8[5] numbers;
    uint256 drawNumber;
  }

  Ticket[] public tickets;

  mapping(uint256 => address) public ticketToOwner;
  mapping(address => uint256[]) public ownerToClaimableTickets;
  mapping(uint256 => uint256[]) public drawToTickets;
  mapping(uint256 => uint256) public drawToTicketCount;
  mapping(address => uint256) ownerTicketCount;

  constructor(address _LTY) {
    LTY = _LTY;
    ILottyToken = LottyToken(_LTY);
  }

  function buyLottyToken() public payable {
    require(msg.value > 0);
    uint256 value = msg.value;
    uint256 amount = value.div(ticketPrice) * 10**ILottyToken.decimals();
    bytes4 mintFunc = bytes4(keccak256(bytes('mint(address,uint256)')));
    (bool success, bytes memory data) = LTY.call(abi.encodeWithSelector(mintFunc, msg.sender, amount));

    require(success && (data.length == 0 || abi.decode(data, (bool))), 'LotteryFactory::buyLottyToken: mint failed');
  }

  function buyRandomTicket(address _owner, uint256 _randomArg) private {
    // Store lotterycount in memory to save some gas
    uint256 lotteryCountMem = lotteryCount;
    uint8[5] memory numbers = generateRandomTicketNumbers(lotteryCountMem + _randomArg);
    tickets.push(Ticket(numbers, lotteryCountMem));
    uint256 id = tickets.length.sub(1);
    ticketToOwner[id] = _owner;
    drawToTickets[lotteryCountMem].push(id);
    ownerToClaimableTickets[_owner].push(id);
  }

  function buyMultipleRandomTicket(uint256 _amount) public {
    // require(msg.value / _amount == ticketPrice, 'Value given is different from the ticket price');
    require(_amount % 1 == 0, 'LotteryFactory::buyMultipleRandomTicket: cannot buy fraction of ticket');
    require(ILottyToken.balanceOf(msg.sender) >= _amount * 10**18, 'LotteryFactory::buyMultipleRandomTicket: not enougth LTY to buy ticket');
    require(ILottyToken.allowance(msg.sender, address(this)) >= _amount * 10**18, 'LotteryFactory::buyMultipleRandomTicket: not enougth allowance');
    // ILottyToken.approve(msg.sender, amount);
    for (uint256 i = 0; i < _amount; i++) {
      buyRandomTicket(msg.sender, i);
    }
    TransferHelper.safeTransferFrom(LTY, msg.sender, address(this), _amount * 10**18);
    drawToTicketCount[lotteryCount] = drawToTicketCount[lotteryCount].add(_amount);
    ownerTicketCount[msg.sender] = ownerTicketCount[msg.sender].add(_amount);
  }

  function setTicketPrice(uint256 _newPrice) external onlyOwner {
    ticketPrice = _newPrice;
  }

  function setRandomNumberGenerator(address _IRandomNumberGenerator) external onlyOwner {
    randomGenerator = IRandomNumberGenerator(_IRandomNumberGenerator);
  }

  function viewRandomNumberGenerator() external view returns (address) {
    return address(randomGenerator);
  }

  function withdraw() external onlyOwner {
    // Withdraw ETH collected for the LTY token sale
    (bool sent, ) = owner().call{value: address(this).balance}('');
    require(sent, 'Failed to send Ether');
    TransferHelper.safeTransfer(LTY, owner(), devFeeBalance);
    devFeeBalance = 0;
  }

  function burn() external onlyOwner {
    // (bool sent, ) = address(LTY).call{value: address(this).balance}('');
    ILottyToken.burn(address(this), burnBalance);
    burnBalance = 0;
  }

  function _getTicketsByOwner(address _owner) external view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](ownerTicketCount[_owner]);
    uint256 counter = 0;
    for (uint256 i = 0; i < tickets.length; i++) {
      if (ticketToOwner[i] == _owner) {
        result[counter] = i;
        counter = counter.add(1);
      }
    }
    return result;
  }

  function _getTicket(uint256 _ticketId) public view returns (Ticket memory) {
    return tickets[_ticketId];
  }

  function _getBalance() public view returns (uint256) {
    return ILottyToken.balanceOf(address(this)) - claimableBalance - stakingBalance - burnBalance - devFeeBalance;
  }

  function _getAllBalances()
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (ILottyToken.balanceOf(address(this)), claimableBalance, devFeeBalance, stakingBalance, burnBalance);
  }

  function _getDrawToTickets(uint256 _drawId) public view returns (uint256[] memory) {
    return drawToTickets[_drawId];
  }

  function viewTicket(uint256 _ticketId)
    public
    view
    returns (
      uint8[5] memory,
      uint256,
      bool
    )
  {
    Ticket memory ticket = tickets[_ticketId];

    uint256[] memory claimableTickets = ownerToClaimableTickets[ticketToOwner[_ticketId]];
    bool claimed = false;
    for (uint256 i = 0; i < claimableTickets.length; i++) {
      if (claimableTickets[i] == _ticketId) {
        claimed = true;
        break;
      }
    }
    return (ticket.numbers, ticket.drawNumber, claimed);
  }

  function isTicketClaimed(uint256 _ticketId) public view returns (bool) {
    uint256[] memory claimableTickets = ownerToClaimableTickets[ticketToOwner[_ticketId]];
    bool claimed = false;
    for (uint256 i = 0; i < claimableTickets.length; i++) {
      if (claimableTickets[i] == _ticketId) {
        claimed = true;
        break;
      }
    }
    return claimed;
  }
}
