// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract LotteryFactory {
  address[] public lotteries;
  mapping(address => string) public lotteryNames;
  mapping(address => string) public lotteryImages;

  function createLottery(
    string memory name,
    string memory imageUrl,
    uint256 unitPrice
  ) public {
    Lottery newLottery = new Lottery(msg.sender, name, imageUrl, unitPrice);
    address lotteryAddress = address(newLottery);
    lotteries.push(lotteryAddress);
    lotteryNames[lotteryAddress] = name;
    lotteryImages[lotteryAddress] = imageUrl;
  }

  function getLotteries()
    public
    view
    returns (
      address[] memory,
      string[] memory,
      string[] memory
    )
  {
    string[] memory _lotteryNames = new string[](lotteries.length);
    string[] memory _lotteryImages = new string[](lotteries.length);
    for (uint256 i = 0; i < lotteries.length; i++) {
      _lotteryNames[i] = lotteryNames[lotteries[i]];
      _lotteryImages[i] = lotteryImages[lotteries[i]];
    }
    return (lotteries, _lotteryNames, _lotteryImages);
  }
}

enum LotteryStatus {
  Initial,
  Active,
  Finished
}

contract Lottery {
  address public factory;
  address public manager;
  string public name;
  string public imageUrl;
  uint256 public unitPrice;
  LotteryStatus public status;
  mapping(address => uint256) public donationRates;
  address[] public donationAddresses;

  mapping(string => uint256) public winnerPrizeRates;
  string[] public winnerPrizes;
  mapping(string => address) public winnerPrizeResults;

  address[] public ticketHolders;
  mapping(address => uint256[]) public ticketsByAddress;

  constructor(
    address creator,
    string memory _name,
    string memory _imageUrl,
    uint256 _unitPrice
  ) {
    factory = msg.sender;
    manager = creator;
    name = _name;
    imageUrl = _imageUrl;
    unitPrice = _unitPrice;
  }

  modifier onlyManager() {
    require(manager == msg.sender);
    _;
  }

  modifier onlyActive() {
    require(status == LotteryStatus.Active);
    _;
  }
  modifier onlyInitial() {
    require(status == LotteryStatus.Initial);
    _;
  }
  modifier onlyFinished() {
    require(status == LotteryStatus.Finished);
    _;
  }

  function getDonationAddresses() public view returns (address[] memory) {
    return donationAddresses;
  }

  function getTicketHolders() public view returns (address[] memory) {
    return ticketHolders;
  }

  function getTicketsByAddress(address user) public view returns (uint256[] memory) {
    return ticketsByAddress[user];
  }

  function getDonationRates() public view returns (address[] memory, uint256[] memory) {
    uint256[] memory rates = new uint256[](donationAddresses.length);
    for (uint256 i = 0; i < donationAddresses.length; i++) {
      rates[i] = donationRates[donationAddresses[i]];
    }
    return (donationAddresses, rates);
  }

  function getWinnerPrizeRates() public view returns (string[] memory, uint256[] memory) {
    uint256[] memory rates = new uint256[](winnerPrizes.length);
    for (uint256 i = 0; i < winnerPrizes.length; i++) {
      rates[i] = winnerPrizeRates[winnerPrizes[i]];
    }
    return (winnerPrizes, rates);
  }

  function addDonation(address to, uint256 rate) public onlyInitial {
    donationRates[to] = rate;
    donationAddresses.push(to);
  }

  function removeDonation(address to) public onlyInitial {
    donationRates[to] = 0;
    address[] memory newDonationAddresses = new address[](donationAddresses.length - 1);
    uint256 innerIndex = 0;
    for (uint256 index = 0; index < donationAddresses.length; index++) {
      if (donationAddresses[index] != to) {
        newDonationAddresses[innerIndex] = donationAddresses[index];
        innerIndex++;
      }
    }
    donationAddresses = newDonationAddresses;
  }

  function addWinnerPrize(string memory prizeName, uint256 rate) public onlyInitial {
    winnerPrizeRates[prizeName] = rate;
    winnerPrizes.push(prizeName);
  }

  function removeWinnerPrize(string memory prize) public onlyInitial {
    winnerPrizeRates[prize] = 0;
  }

  function activation() public onlyManager onlyInitial {
    status = LotteryStatus.Active;
  }

  function finish() public onlyManager onlyActive {
    status = LotteryStatus.Finished;
  }

  function buyTicket() public payable onlyActive {
    require(msg.value == unitPrice);
    uint256 ticketId = ticketHolders.length + 1;
    ticketHolders.push(msg.sender);
    ticketsByAddress[msg.sender].push(ticketId);
  }

  function totalRate() public view returns (uint256) {
    uint256 _totalRate = 0;
    for (uint256 i = 0; i < donationAddresses.length; i++) {
      _totalRate += donationRates[donationAddresses[i]];
    }
    for (uint256 i = 0; i < winnerPrizes.length; i++) {
      _totalRate += winnerPrizeRates[winnerPrizes[i]];
    }
    return _totalRate;
  }

  function random() private view returns (uint256) {
    bytes memory seed = abi.encodePacked(block.difficulty, block.timestamp, ticketHolders);
    return uint256(keccak256(seed));
  }

  function distributePrizes() public onlyFinished onlyManager {
    uint256 _totalRate = totalRate();
    uint256 totalBalance = address(this).balance;
    for (uint256 i = 0; i < donationAddresses.length; i++) {
      address donationAddress = donationAddresses[i];
      uint256 prizeRate = donationRates[donationAddress];
      uint256 prizeAmount = (totalBalance * prizeRate) / _totalRate;
      payable(donationAddress).transfer(prizeAmount);
    }

    for (uint256 i = 0; i < winnerPrizes.length; i++) {
      string memory winnerPrize = winnerPrizes[i];
      uint256 prizeRate = winnerPrizeRates[winnerPrize];
      uint256 prizeAmount = (totalBalance * prizeRate) / _totalRate;
      uint256 index = random() % ticketHolders.length;
      address winner = ticketHolders[index];
      winnerPrizeResults[winnerPrize] = winner;
      payable(winner).transfer(prizeAmount);
    }
    if (address(this).balance > 0) {
      // 端数はmanagerに戻す。
      payable(manager).transfer(address(this).balance);
    }
  }
}
