// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";
import "./OwnerAble.sol";

contract BelotterContract is OwnerAble{

  using SafeMath for uint;
  using SafeMath for uint8;
  using SafeMath for uint16;

  // user id => user address
  address[] private users;

  // nounce
  uint private nounce = 0;

  // commission percent
  uint8 private commissionPercent = 5;

  // user default chance
  uint16 private defaultChance = 1000;

  // stake total amounts
  uint private stakeTotalAmounts = 0;

  // stake total rewards
  uint private stakeTotalRewards = 0;

  // market capacity
  uint private marketCapacity = 0;

  // market total sell count
  uint private marketTotalSellCount = 0;

  // market total sell price
  uint private marketTotalSellPrice = 0 ether;

  // airdrop min user count
  uint private airdropMinUserCount = 100;

  // airdrop min lottery count
  uint private airdropMinLotteryCount = 50;

  // airdrop last time
  uint private airdropLastTime = 0;

  // airdrop wait time
  uint private airdropWaitTime = 1 weeks;

  // airdrop amount
  uint private airdropReward = 5 * defaultChance;

  // airdrop total rewards
  uint private airdropTotalRewards = 0;

  // lottery count
  uint private lotteryCount = 0;

  // lottery max user count
  uint8 private lotteryMaxUser = 5;

  // lottery join price
  uint private lotteryJoinPrice = 10 ether;

  // wait time for next join
  uint private lotteryJoinWaitTime = 3 hours;

  // lottery total rewards
  uint private lotteryTotalRewards = 0 ether;

  // price per chance
  uint private pricePerChance = 2 * lotteryJoinPrice / defaultChance;

  // user => time
  mapping (address => uint) private lotteryLastJoinTime;

  // user => lotteryId
  mapping (address => uint) private lotteryJoinedId;

  // lotteryId => users
  mapping (uint => address[]) private lotteryUsers;

  // lotteryId => winner
  mapping (uint => address) private lotteryWinner;

  // lotteryId => min
  mapping (uint => uint[]) private lotteryMinimums;

  // lotteryId => max
  mapping (uint => uint[]) private lotteryMaximums;

  // user address => user main chance
  mapping(address => uint) private mainChance;

  // user address => user extra chance
  mapping(address => uint) private extraChance;

  // user address => user in market chance
  mapping(address => uint) private marketChance;

  // user address => user stake chance
  mapping(address => uint) private stakeChance;

  struct Data {
    uint lotteryCount;
    uint lotteryTotalRewardsInWei; 
    uint lotteryMaxUser;
    uint lotteryJoinPriceInWei;
    uint lotteryJoinWaitTime;
    uint marketTotalSellCount;
    uint marketTotalSellPriceInWei;
    uint marketCapacity;
    uint stakeTotalAmounts;
    uint stakeTotalRewards;
    uint airdropMinLotteryCount;
    uint airdropMinUserCount;
    uint airdropLastTime;
    uint airdropWaitTime;  
    uint airdropTotalRewards; 
    uint pricePerChanceInWei;
    uint16 defaultChance;
    address owner;
    address[] users;
  }

  struct userData {
    uint lotteryLastJoinTime;
    uint lotteryJoinedId;
    uint mainChance;
    uint extraChance;
    uint marketChance;
    uint stakeChance;
  }

  struct LotteryData {
    uint[] min;
    uint[] max;
    address[] users;
    address winner;
  }

  function _rand() private returns (uint) {
    nounce = nounce.add(block.timestamp);
    uint rand1 = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, nounce))).div(10000);
    nounce = nounce.add(block.timestamp);
    uint rand2 = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, nounce))).div(10000000);
    return rand1.sub(rand2);
  }

  function _rand(uint _min, uint _max) private returns (uint) {
    return _rand().between(_min, _max);
  }

  function getData() public view returns (Data memory) {
    return Data(      
      lotteryCount,
      lotteryTotalRewards,
      lotteryMaxUser,
      lotteryJoinPrice,
      lotteryJoinWaitTime,
      marketTotalSellCount,
      marketTotalSellPrice,
      marketCapacity,
      stakeTotalAmounts,
      stakeTotalRewards,
      airdropMinLotteryCount,
      airdropMinUserCount,
      airdropLastTime,
      airdropWaitTime,
      airdropTotalRewards,
      pricePerChance,
      defaultChance,
      owner(),
      users
    );
  }

  function getUserData(address _address) public view returns (userData memory) {
    return userData(      
      lotteryLastJoinTime[_address],
      lotteryJoinedId[_address],
      mainChance[_address],
      extraChance[_address],
      marketChance[_address],
      stakeChance[_address]
    );
  }

  function getLotteryData(uint _lotteryId) public view returns (LotteryData memory) {
    return LotteryData(      
      lotteryMinimums[_lotteryId],
      lotteryMaximums[_lotteryId],
      lotteryUsers[_lotteryId],
      lotteryWinner[_lotteryId]
    );
  }

  function sell(uint _sellAmount) public {

    // get seller chance amount
    uint amount = extraChance[msg.sender];

    // check seller extra chance amount
    require(amount > 0, 'You do not have extra chance');

    // check sell amount less than extra amount
    require(_sellAmount <= amount, 'You can not sell more than extra chance');

    // dec seller extra chance amount
    extraChance[msg.sender] = extraChance[msg.sender].sub(_sellAmount);

    // inc seller market chance amount
    marketChance[msg.sender] = marketChance[msg.sender].add(_sellAmount);

    // inc market total amount
    marketCapacity = marketCapacity.add(_sellAmount);

  }

  function unsell(uint _unsellAmount) public {

    // get sell order amount
    uint amount = marketChance[msg.sender] - stakeChance[msg.sender];

    // check sell order amount
    require(amount > 0, 'You do not have sell order');

    // check unsell amount less than sell order amount
    require(_unsellAmount <= amount, 'You can not decrease more than sell order');

    // dec sell order
    marketChance[msg.sender] = marketChance[msg.sender].sub(_unsellAmount);

    // inc extra chance amount
    extraChance[msg.sender] = extraChance[msg.sender].add(_unsellAmount);

    // dec market total amount
    marketCapacity = marketCapacity.sub(_unsellAmount);

  }

  function stake(uint _stakeAmount) public {

    // get staker extra chance amount
    uint amount = extraChance[msg.sender];

    // check staker extra chance amount
    require(amount > 0, 'You do not have extra chance');

    // check stake amount less than extra amount
    require(_stakeAmount <= amount, 'You can not stake more than extra chance');

    // dec staker extra chance amount
    extraChance[msg.sender] = extraChance[msg.sender].sub(_stakeAmount);

    // inc stake chance amount
    stakeChance[msg.sender] = stakeChance[msg.sender].add(_stakeAmount);

    // inc staker sell order amount
    marketChance[msg.sender] = marketChance[msg.sender].add(_stakeAmount);

    // inc market total amount
    marketCapacity = marketCapacity.add(_stakeAmount);

    // inc stake total amount
    stakeTotalAmounts = stakeTotalAmounts.add(_stakeAmount);

  }

  function unstake(uint _unstakeAmount) public {

    // get stake amount
    uint amount = stakeChance[msg.sender];

    // check sell order amount
    require(amount > 0, 'You do not have stake chacne');

    // check unstake amount less than stake amount
    require(_unstakeAmount <= amount, 'You can not decrease more than stake amount');

    // dec stake amount
    stakeChance[msg.sender] = stakeChance[msg.sender].sub(_unstakeAmount);

    // inc extra chance amount
    extraChance[msg.sender] = extraChance[msg.sender].add(_unstakeAmount);

    // dec stake total amount
    stakeTotalAmounts = stakeTotalAmounts.sub(_unstakeAmount);

  }

  function buy(uint _buyTotalAmount) public payable {

    // check sell exists
    require(marketCapacity > 0, 'Do not have any seller');

    // check amount not zero
    require(_buyTotalAmount > 0, 'You can not buy 0 chance');

    // check amount less than market total amount
    require(_buyTotalAmount <= marketCapacity, 'You can not buy more than market capacity');

    // check send valid money
    require(msg.value == _buyTotalAmount.mull(pricePerChance) , 'You do not send valid money');

    // get commission
    uint commission = msg.value.percent(commissionPercent);

    // transfer commission to owner
    payable(owner()).transfer(commission);

    // dec market total amount
    marketCapacity = marketCapacity.sub(_buyTotalAmount);

    // inc buyer extra chance
    extraChance[msg.sender] = extraChance[msg.sender].add(_buyTotalAmount);

    // inc market total sell count
    marketTotalSellCount = marketTotalSellCount.increase();

    // inc market total sell price
    marketTotalSellPrice = marketTotalSellPrice.add(msg.value);

    // each all users
    for(uint i=0; i<users.length; i++) {

      // get user
      address seller = users[i];

      // get sell amount
      uint sellAmount = marketChance[seller];

      // check sell amount
      if(sellAmount == 0) continue;

      // get buy amount
      uint amount = _buyTotalAmount > sellAmount ? sellAmount : _buyTotalAmount;

      // dec buy order
      marketChance[seller] = marketChance[seller].sub(amount);

      // dec buy amount
      _buyTotalAmount = _buyTotalAmount.sub(amount);

      // get amount price
      uint price = amount.mull(pricePerChance).percent(100 - commissionPercent);

      // get stake percent of amount
      uint8 stakePercent = uint8(stakeChance[seller].mull(100).div(amount));

      // get stake price of amount price
      uint stakePrice = price.percent(stakePercent);

      // transfer stake price to owner
      payable(owner()).transfer(stakePrice);

      // dec stake price
      price = price.sub(stakePrice);

      // transfer money to seller
      payable(seller).transfer(price);

      // check buy amount
      if(_buyTotalAmount == 0) break;

    }

  }

  function airdrop() public onlyOwner() {

    // check staker exists in users
    require(stakeTotalAmounts > 0, 'Staker not exists');

    // check user count
    require(users.length >= airdropMinUserCount, 'Users count is less than 100');

    // check lottery count
    require(lotteryCount >= airdropMinLotteryCount, 'Loteries count is less than 50');

    // check airdrop time
    require(block.timestamp >= airdropLastTime.add(airdropWaitTime), 'You can not airdrop now please wait');
    
    // generate random number
    uint rand = _rand(0, users.length);

    address staker = address(0);

    // selcet staker befor rand becuse old users are expencive
    for(uint i=rand; i>=0; i--) {
      if(stakeChance[users[i]] > 0) { 
        staker = users[i];
        break; 
      }
    }

    // selcet staker after rand
    if(staker == address(0)) {
      for(uint i=rand+1; i<users.length; i++) {
        if(stakeChance[users[i]] > 0) { 
          staker = users[i];
          break; 
        }
      }
    }

    // not found staker
    if(staker == address(0)) {
      return;
    }

    // inc staker chance
    extraChance[staker] = extraChance[staker].add(airdropReward);

    // inc airdrop total rewards
    airdropTotalRewards = airdropTotalRewards.add(airdropReward);

    // set airdrop time
    airdropLastTime = block.timestamp;

  }

  function join() public payable {

    // check valid price
    require(msg.value == lotteryJoinPrice, 'You must send equal 1 matic');
    
    // register user if not exist
    if(mainChance[msg.sender] == 0) {

      // push user
      users.push(msg.sender);

      // set user chance to default
      mainChance[msg.sender] = defaultChance;

    }

    // check user last join time
    require(block.timestamp > lotteryLastJoinTime[msg.sender].add(lotteryJoinWaitTime), 'You can not join lottery now please wait');
    
    // check not joined 
    require(lotteryJoinedId[msg.sender] == 0, 'You joined in lottery');

    // create new lottery if empty lottery or last lottery is full
    if(lotteryCount == 0 || lotteryUsers[lotteryCount].length == lotteryMaxUser) {

      // inc lottery count
      lotteryCount = lotteryCount.increase();

      // set minmimums to zero
      lotteryMinimums[lotteryCount] = new uint[](lotteryMaxUser);

      // set maxmimums to zero
      lotteryMaximums[lotteryCount] = new uint[](lotteryMaxUser);

    }

    // join to last lottery
    _joinLastLottery();

    // start lottery if full
    if(lotteryUsers[lotteryCount].length < lotteryMaxUser) {
      return;
    }

    // get lottery reward
    uint reward = lotteryJoinPrice.mull(lotteryMaxUser);

    // get commission
    uint commission = reward.percent(commissionPercent);

    // transfer commission
    payable(owner()).transfer(commission);

    // set reward
    reward = reward.sub(commission);
    
    // generate random number
    uint rand = _rand(0 , lotteryMaximums[lotteryCount][lotteryMaxUser.decrease()]);

    // each user in selected lottery
    for(uint i=0; i<lotteryMaxUser; i++) {

      // get min
      uint min = lotteryMinimums[lotteryCount][i];

      // get max
      uint max = lotteryMaximums[lotteryCount][i];

      // get user
      address user = lotteryUsers[lotteryCount][i];

      // user win lottery
      if(rand.isBetween(min, max)) {

        // set lottery winner
        lotteryWinner[lotteryCount] = user;

        // send reward to winner
        payable(user).transfer(reward);

        // inc total lottery rewards
        lotteryTotalRewards = lotteryTotalRewards.add(reward);

        // winner new chance
        uint wChance = defaultChance / 2;

        // stakers reward
        uint stakersReward = _getUserJoinChance(user).sub(wChance);

        // set winner main chance
        mainChance[user] = wChance;

        // set winner extra chance
        extraChance[user] = 0;

        // division stakers reward
        _divsionStakersReward(stakersReward);

      }

      // user loss lottery
      else {

        // inc looser chance
        extraChance[user] = extraChance[user].add(defaultChance.percent(5));

      }

      // remove lottery joined 
      lotteryJoinedId[user] = 0;

    }

  }

  function _joinLastLottery() private {

    // get user index
    uint index = lotteryUsers[lotteryCount].length;

    // get min  
    uint min = lotteryMinimums[lotteryCount][index];

    // get max
    uint max = min.add(_getUserJoinChance(msg.sender));

    // cache max
    lotteryMaximums[lotteryCount][index] = max;

    // cache next user min if not last user
    if(index < lotteryMaxUser.sub(1))
      lotteryMinimums[lotteryCount][index.increase()] = max.increase();

    // push user to last lottery
    lotteryUsers[lotteryCount].push(msg.sender);

    // update joined lottery
    lotteryJoinedId[msg.sender] = lotteryCount;

    // update last join time
    lotteryLastJoinTime[msg.sender] = block.timestamp;

  }

  function _getUserJoinChance(address _address) private view returns (uint) {
    return mainChance[_address].add(extraChance[_address]);
  }

  function _divsionStakersReward(uint _amount) private {

    // each user
    for(uint i=0; i < users.length; i++) {

      // get user
      address user = users[i];

      // get stake amount
      uint amount = stakeChance[user];

      // check stake amount
      if(amount == 0) { continue; }

      // get staker percent of total stake amount
      uint8 percent = uint8(amount * 100 / stakeTotalAmounts);

      // get staker reward chance amount
      uint reward = _amount.percent(percent);

      // inc staker extra chance
      extraChance[user] = extraChance[user].add(reward);

      // inc stake total rewards
      stakeTotalRewards = stakeTotalRewards.add(reward);

    }
    
  }

}