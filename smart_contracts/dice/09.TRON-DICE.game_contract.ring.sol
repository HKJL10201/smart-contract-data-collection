pragma solidity ^ 0.4.25;

interface MineIF {
    function mine(address user, address dev, uint amount) external;
}

interface ReferIF {
    function refer(address user, uint amount, address referrer) external payable;
}

interface RankIF {
    function ranking(address user, uint amount) external payable;
}

interface DivideIF {
    function dividePay() external payable;
}

contract Ring {
    using SafeMath for uint256;
    
    event RingLottory(address indexed user, uint256 currentBet, uint256 color, uint256 playAmount, uint256 totalPrize);
    event RingWin(uint256 term, uint256 winNum, uint256 color);
    event RingDraw(address indexed winner, uint256 prize, uint256 term);
    event RingFinish(address indexed user, uint256 money, uint256 term);
    event RingStart(address indexed user, uint256 term);

    address owner;
    address public developer;
    address public marketer;
    address public poolAddr;
    
    address public mineCtx;
    address public referCtx;
    address public rankCtx;

    function setMineIF(address addr) public onlyDev {
        require(address(0)!=addr);
        mineCtx = addr;
    }

    function setReferIF(address addr) public onlyDev {
        require(address(0)!=addr);
        referCtx = addr;
    }

    function setRankIF(address addr) public onlyDev {
        require(address(0)!=addr);
        rankCtx = addr;
    }
    
    struct BetUser {
        address[] users;
        uint[] prizes;
        uint totalPrize;
    }
    struct ColorInfo {
        uint muti;
        uint betMax;
    }
    
    struct BetInfo {
        uint256 totalReceived;                      /// 本轮次总收入
        uint256 totalProfile;                       /// 本轮次总利润
        uint256  totalLose;                         /// 本轮次总亏损 
        uint256 totalReward;                        /// 本轮次总奖励

        mapping(uint => BetUser) betUsers;          /// colors index -> bet user list under color
        
        uint winNumber;                             /// 中奖号码 
        uint winColor;                              ///  中奖色段 
        
        uint startTime;                             /// 当前轮次开始时间 
        uint endTime;                               /// 当前轮次结束时间 
    }

    enum State {
        Ongoing,
        Pending,
        Finished
    }
    State public state;

    uint256 public currentBet;                      /// 当前轮次id 
    mapping(uint256 => BetInfo) public bets_;       /// all history play data
    
    uint[] public colors;                           /// colors: 1-black,2-red,3-green,4-yellow
    uint[] public colorNumbers;                     /// ring with color, 0-53
    
    mapping(uint => ColorInfo) public colorInfo;

    
    uint256 public totalReceive;                    /// 历史总流水 
    uint256 public totalProfile;                    /// 历史总利润 
    uint256 public totalPlayCount;                  /// 历史开奖次数 
    
    uint256 public roundTime = 18;                  /// 每轮次投注时间间隔 ，18s
    uint256 public endTime_;                        /// 当前轮次结束时间  startTime+roundTime

    uint256 constant SUN = 1000000;
    uint256 constant MIN_PRICE = 10 * SUN;          /// 最低投注额 

    uint256 public poolRate = 50;                   /// POOL_RATE
    uint256 public developerRate = 20;              /// DEVELOPER_RATE
    uint256 public marketRate = 0;                  /// MARKET_RATE   the rest will send to market 
    uint256 public referRate = 2;                  /// REFER_RATE
    uint256 public rankRate = 1;                    /// RANK_RATE

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyDev() {
        require(msg.sender == developer);
        _;
    }

    modifier finished() {
        require(state == State.Finished, "not finished!!!");
        _;
    }

    modifier started() {
        require(state == State.Ongoing, "not start yet");
        require(now < endTime_,"finished yet");
        _;
    }

    modifier pending() {
        require(state == State.Pending, "not finished yet");
        _;
    }
    
    function setRate(uint poolRate_,uint developerRate_,uint marketRate_,uint referRate_,uint rankRate_,uint rewardRate_) public onlyOwner{
        require(poolRate_ + developerRate_ + marketRate_ + referRate_ + rankRate_ == rewardRate_);
        poolRate = poolRate_;
        developerRate = developerRate_;
        marketRate = marketRate_;
        referRate = referRate_;
        rankRate = rankRate_;
    }
    
    function initColorInfo(uint[] mutis, uint[]max) public onlyDev{
        require(colors.length == 4);
        require(mutis.length == 4);
        for (uint i=0; i < 4; i++){
            ColorInfo memory color;
            color.muti = mutis[i];
            color.betMax = max[i];
            colorInfo[i+1] = color;
        }
    } 

    function initColor() public onlyDev{
        // black id 1,red id 2,green id 3,yellow id 4
        require(colors.length==0);
        for (uint i=0; i < 4; i++){
            colors.push(i+1);
        }
    }
    function initColorNumbers(uint256[] colorArr) public onlyDev{
        if (colorArr.length == 0){
            colorNumbers = new uint256[](54);
            colorNumbers = [4,3,1,2,1,2,1,2,1,3,1,3,1,2,1,2,1,2,1,3,1,3,1,2,1,2,1,2,1,2,1,2,1,3,1,3,1,2,1,2,1,2,1,3,1,3,1,2,1,2,1,2,1,3];
        }else{
            colorNumbers = new uint256[](colorArr.length);
            colorNumbers = colorArr;
        }
    }

    constructor() public {
        owner = msg.sender;
        developer = msg.sender;
        poolAddr = msg.sender;
        marketer = msg.sender;

        state = State.Finished;
    }
    
    function setPool(address _addr) public onlyOwner {
        require(address(0) != _addr);
        poolAddr = _addr;
    }
    
    function setDeveloper(address _addr) public onlyOwner {
        require(address(0) != _addr);
        developer = _addr;
    }
    
    function setMarket(address _addr) public onlyOwner {
        require(address(0) != _addr);
        marketer = _addr;
    }
    
    function balance() public view returns(uint256) {
        return address(this).balance;
    }
    

    function start() public payable onlyDev {
        require(msg.value == 0);
        __start();
    }
    
    function __start() internal finished {
        if (currentBet==0){
            currentBet++;
        }
        BetInfo storage betInfo = bets_[currentBet];
        if (betInfo.totalReceived > 0){
            currentBet++;
            betInfo = bets_[currentBet];
        }

        //betInfo.totalReceived = 0;
        //betInfo.totalLose = 0;
        //betInfo.totalProfile = 0;
        
        betInfo.startTime = now;
        endTime_ = now.add(roundTime);
        betInfo.endTime = endTime_;
        
        state = State.Ongoing;
        
        emit RingStart(msg.sender, currentBet);
    }
    
    function buy(address referer, uint color) public payable started {
        require(msg.value > MIN_PRICE, "not sufficient fee!");
        require(color==1||color==2||color==3||color==4);
        
        BetInfo storage betInfo = bets_[currentBet];
        BetUser storage user = betInfo.betUsers[color];
        
        require(user.totalPrize.add(msg.value) <= colorInfo[color].betMax) ;
         
        user.users.push(msg.sender);
        user.prizes.push(msg.value);
        user.totalPrize=user.totalPrize.add(msg.value);
        
        betInfo.totalReceived= betInfo.totalReceived.add(msg.value);
        totalReceive = totalReceive.add(msg.value);
        
        MineIF(mineCtx).mine(msg.sender, developer, msg.value);

        if (address(0) != referCtx && referRate > 0){
            ReferIF(referCtx).refer.value(msg.value * referRate / 1000)(msg.sender, msg.value, referer);
        }
        
        if(address(0) != rankCtx && rankRate > 0){
            RankIF(rankCtx).ranking.value(msg.value * rankRate / 1000)(msg.sender, msg.value);
        }

        totalPlayCount++;
        
        emit RingLottory(msg.sender, currentBet, color, msg.value, user.totalPrize);
    }

    function draw(uint256 winNum) public payable onlyDev {
        require(winNum >= 0 && winNum < 54);
        
        BetInfo storage betInfo = bets_[currentBet];

        if (betInfo.totalReceived == 0) {
            state = State.Finished;
            emit RingWin(currentBet, winNum, betInfo.winColor);
            return;
        }
        
        betInfo.winNumber = winNum;
        betInfo.winColor = colorNumbers[betInfo.winNumber];
        
        _sendProfile();
        
        state = State.Finished;

        emit RingWin(currentBet, winNum, betInfo.winColor);
    }
    
    
    function _sendProfile() internal  {
      
        uint256 currentReward_;
        BetInfo storage betInfo = bets_[currentBet];

        currentReward_ = betInfo.betUsers[betInfo.winColor].totalPrize * colorInfo[betInfo.winColor].muti;
        require(address(this).balance>=currentReward_, "reward pool not satisfied");
        
        if (betInfo.totalReceived < currentReward_){
            betInfo.totalProfile = 0;
            betInfo.totalLose = currentReward_.sub(betInfo.totalReceived);
            totalProfile = totalProfile.sub(betInfo.totalLose);
            
        }else{
            betInfo.totalProfile = betInfo.totalReceived.sub(currentReward_);
            betInfo.totalLose = 0;
            totalProfile = totalProfile.add(betInfo.totalProfile);
        }
        
        for (uint i = 0;i < betInfo.betUsers[betInfo.winColor].users.length;i++){
            betInfo.betUsers[betInfo.winColor].users[i].transfer(betInfo.betUsers[betInfo.winColor].prizes[i] * colorInfo[betInfo.winColor].muti);

            emit RingDraw(betInfo.betUsers[betInfo.winColor].users[i], betInfo.betUsers[betInfo.winColor].prizes[i], currentBet);  
        }
        
        if (betInfo.totalProfile <= 0){
            return;
        }

        if (address(0) != poolAddr && poolRate >0 ){
            DivideIF(poolAddr).dividePay.value(betInfo.totalProfile * poolRate / 100)();
            //poolAddr.transfer(betInfo.totalProfile * poolRate / 100);
        }
        if (address(0) != owner && developerRate > 0){
            owner.transfer(betInfo.totalProfile * developerRate / 100);
        }
        if (address(0) != owner && marketRate > 0){
            owner.transfer(betInfo.totalProfile * marketRate / 100);
        }
        
    }
    
    /// --------query function---------
    // all history win info 
    function getWinNumbers(uint256 st, uint256 et) public view returns(uint256[] memory,uint[] memory){

        require(st >=1 && st <= et && et.sub(st) <= 100);
        
        if (et >= currentBet) {
            et = currentBet;
            if (st > et) {
                st = et;
            }
        }
        
        uint256[] memory winNumbers = new uint256[](et - st+1);
        uint[] memory winColors = new uint[](et - st+1);
        
        for (uint i = st; i <= et; i++) {
            BetInfo storage betInfo = bets_[i];
            winNumbers[i-st] = betInfo.winNumber;
            winColors[i-st] = betInfo.winColor;
        }
        
        return (winNumbers, winColors);
    }
    
    function getPlayer(uint256 betID,uint256 color) public view returns (address[] memory,uint256[] memory,uint256){
        require(color == 1 || color == 2 || color == 3 || color ==4);
        require(betID <= currentBet);
        
        BetInfo storage betInfo = bets_[betID];
        address[] memory  userArr = betInfo.betUsers[color].users;
        uint256[] memory  priceArr = betInfo.betUsers[color].prizes;
        
        return (userArr, priceArr, betInfo.betUsers[color].totalPrize);
    }
  
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
