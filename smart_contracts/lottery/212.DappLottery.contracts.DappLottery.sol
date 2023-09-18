// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol'; //区分 管理者账户 与 参与者账户 的一个方法库
import '@openzeppelin/contracts/utils/Counters.sol'; //提供只能递增、递减或重置的计数器。这可以用于例如跟踪映射中的元素数量、发布ERC721 id或计数请求id。

contract DappLottery is Ownable {
  // using for --> 将特定方法绑定到特定类型
  using Counters for Counters.Counter;
  Counters.Counter private p_totalLotteries;

  // struct
  struct LotteryStruct {
    uint256 id;
    string title;
    string image;
    string description;
    uint256 ticketPrice;
    uint256 participants;
    uint256 prize;
    uint256 createdAt;
    uint256 expiresAt;
    bool drawn;
    address owner;
    uint256 winners;
  }

  struct ParticipantStruct {
    address account;
    string luckyNumber;
    bool paid;
  }

  struct LotteryResultStruct {
    uint256 id;
    bool completed;
    bool paidout;
    uint256 timestamp;
    uint256 sharePerWinner;
    ParticipantStruct[] winners;
  }

  //   mapping
  mapping(uint256 => LotteryStruct) lotteries;
  mapping(uint256 => ParticipantStruct[]) lotteryParticipants;
  mapping(uint256 => string[]) lotteryLuckyNumbers; //每个lottery的 所有 可选择的 luckyNumber
  mapping(uint256 => mapping(uint256 => bool)) luckyNumberUsed; //已经被买走的数字
  mapping(uint256 => LotteryResultStruct) lotteryResult;

  //  全局 活动价格相关 && 平台抽成
  uint256 public serviceBalance;
  uint256 public servicePercent;

  //抽成
  constructor(uint256 _servicePercent) {
    servicePercent = _servicePercent;
  }

  // function
  function createLottery(
    string memory title,
    string memory description,
    string memory image,
    uint256 prize,
    uint256 ticketPrice,
    uint256 expiresAt
  ) public {
    require(bytes(title).length > 0, 'title cannot be empty');
    require(bytes(description).length > 0, 'description cannot be empty');
    require(bytes(image).length > 0, 'image cannot be empty');
    require(prize > 0 ether, 'prize cannot be zero');
    require(ticketPrice > 0 ether, 'tickerPrice cannot be zero');
    require(expiresAt > block.timestamp * 1000, 'expiresAt cannot be less than the future');
    p_totalLotteries.increment(); //合约数+1
    //创造 并记录一个 lottery活动
    LotteryStruct memory lottery;
    lottery.id = p_totalLotteries.current();
    lottery.title = title;
    lottery.image = image;
    lottery.ticketPrice = ticketPrice;
    lottery.description = description;
    lottery.prize = prize;
    lottery.createdAt = block.timestamp;
    lottery.expiresAt = expiresAt;
    lottery.owner = msg.sender;
    lotteries[lottery.id] = lottery;
  }

  // 作为合约部署者有权引入  luckyNumbers
  function importLuckyNumber(uint256 id, string[] memory luckyNumbers) public {
    require(lotteries[id].owner == msg.sender, 'Unauthorized entity');
    require(lotteryLuckyNumbers[id].length < 1, 'Already generated');
    require(luckyNumbers.length > 0, 'LuckyNumber cannot be zero');
    lotteryLuckyNumbers[id] = luckyNumbers;
  }

  // 购买指定idlottery的 彩票 || luckyNumber
  function buyTicket(uint256 id, uint256 luckyNumberId) public payable {
    require(!luckyNumberUsed[id][luckyNumberId], 'Lucky number already used'); //先到先得
    require(luckyNumberId <= lotteryLuckyNumbers[id].length, 'luckyNumber is absent');
    require(msg.value >= lotteries[id].ticketPrice, 'insufficient etners to buy ethers'); //是否资金不足
    lotteries[id].participants++;
    lotteryParticipants[id].push(
      ParticipantStruct(msg.sender, lotteryLuckyNumbers[id][luckyNumberId], false)
    );
    luckyNumberUsed[id][luckyNumberId] = true;
    serviceBalance += msg.value;
  }

  // winner
  function randomlySelectWinners(uint256 id, uint256 numOfWiners) public {
    require(
      lotteries[id].owner == msg.sender || lotteries[id].owner == owner(),
      'Unauthorized entity'
    );
    require(lotteries[id].expiresAt > block.timestamp * 1000, 'Event deadline not reached');

    require(!lotteryResult[id].completed, 'Lottery have already been completed');
    require(
      numOfWiners <= lotteryParticipants[id].length,
      'Number of winners exceeds number of participants'
    );
    //初始化一个数组来储存选择的 winner
    ParticipantStruct[] memory winners = new ParticipantStruct[](numOfWiners);
    ParticipantStruct[] memory participants = lotteryParticipants[id]; //所有参赛人员
    // 初始化一个数组 按递增的数字 代表参赛人员 将所有人员均可索引查询
    uint256[] memory indices = new uint256[](participants.length);
    for (uint256 i = 0; i < participants.length; i++) {
      indices[i] = i;
    }
    // 使用Fisher-Yates(随机置乱算法 发牌算法)打乱indices 制造随机
    for (uint256 i = participants.length - 1; i >= 1; i--) {
      uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % (i + 1); //keccak256是hash算法 抗碰撞随意j的每次取值都不同 且变化极大
      uint256 temp = indices[j];
      indices[j] = indices[i];
      indices[i] = temp;
    }
    // Select the winners
    for (uint256 i = 0; i < numOfWiners; i++) {
      winners[i] = participants[indices[i]];
      lotteryResult[id].winners.push(winners[i]);
    }
    lotteryResult[id].id = id;
    lotteryResult[id].completed = true;
    lotteryResult[id].timestamp = block.timestamp;
    lotteries[id].winners = lotteryResult[id].winners.length;
    lotteries[id].drawn = true;
    payLotteryWinner(id);
  }

  function payLotteryWinner(uint256 id) internal {
    ParticipantStruct[] memory winners = lotteryResult[id].winners;
    uint256 totalShares = lotteries[id].ticketPrice * lotteryParticipants[id].length;
    uint256 platformShare = (totalShares * servicePercent) / 100;
    uint256 userShares = totalShares - platformShare;
    uint256 perWinnerShares = userShares / winners.length;
    for (uint256 i = 0; i < winners.length; i++) {
      payTo(winners[i].account, perWinnerShares);
    }
    serviceBalance -= totalShares;
    lotteryResult[id].id = id;
    lotteryResult[id].paidout = true;
    lotteryResult[id].sharePerWinner = perWinnerShares;
  }

  function payTo(address to, uint256 totalPrice) internal {
    (bool success, ) = payable(to).call{ value: totalPrice }('');
    require(success);
  }

  // get function
  function getLotteries() public view returns (LotteryStruct[] memory Lotteries) {
    Lotteries = new LotteryStruct[](p_totalLotteries.current());
    for (uint256 i = 1; i <= p_totalLotteries.current(); i++) {
      Lotteries[i - 1] = lotteries[i];
    }
  }

  function getLottery(uint256 _id) public view returns (LotteryStruct memory) {
    return lotteries[_id];
  }

  function getLotteryParticipants(uint256 _id) public view returns (ParticipantStruct[] memory) {
    return lotteryParticipants[_id];
  }

  function getLotteryLuckyNumbers(uint256 _id) public view returns (string[] memory) {
    return lotteryLuckyNumbers[_id];
  }

  function getLotteryResult(uint256 id) public view returns (LotteryResultStruct memory) {
    return lotteryResult[id];
  }
}
// lotteries 合约记录 id索引
// lotteryLuckyNumbers  在这个活动里，数字是已经生成好的就是import的这些数字，特定的lotteryid有自己的luckyNumber数组
// luckyNumberUsed 判断luckyNumber是否已经被买走   luckyNumberUsed[2][asdfas] = true; 证明lottery2的luckyNumberId asdfas已经被买走
// lotteryParticipants  id => ParticipantStruct[]  每有一个用户购买ticket就会push一个 ParticipantStruct 进入lotteryParticipants数组
