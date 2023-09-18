pragma solidity ^0.4.25;

interface MineIF {
    function mine(address user, address dev, uint amount) external;
}

interface ReferIF {
    function refer(address user, uint amount, address referrer) external payable;
}

interface RankingIF {
    function ranking(address user, uint amount) external payable;
}

interface DivideIF {
    function dividePay() external payable;
}

library SafeMath {
    function sub(uint a, uint b) internal pure returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}


contract LuckyHash {
    using SafeMath for uint;

    event LuckLottory(address indexed user, uint term, uint start, uint end); // 购买事件
    event Draw(address winer, uint luckNumber, uint prize, uint termID, uint rank); // 开奖事件
    event TermEnd(uint termID, uint rank, uint drawBlock, uint drawBlockNum); // 轮次结束事件

    address public mineCtx;
    address public referCtx;
    address public rankCtx;

    function setMineIF(address addr) public onlyDev {
        mineCtx = addr;
    }

    function setReferIF(address addr) public onlyDev {
        referCtx = addr;
    }

    function setRankIF(address addr) public onlyDev {
        rankCtx = addr;
    }

    uint public playCnt;        // 总参与人次
    uint public totalReceive;   // 总收入流水
    uint public totalBonus;     // 总开奖分红额度

    uint public drawBlockGap = 40;      // 开奖区块和游戏结束区块的差值
    uint public drawBlockNum = 13;      // 开奖所需的连续区块数
    uint public drawRankGap = 5;        // 各名次开奖区块间隔

    function setDrawBlockLimit(uint gap, uint num, uint rankGap) public onlyDev {
        require(gap >= 5 && num >= 8 && rankGap >=3);
        drawBlockGap = gap;
        drawBlockNum = num;
        drawRankGap = rankGap;
    }

    uint[] prizeRate;       // 前三名的奖金分成比例: 50, 30, 10, 剩余10为运营分成
    uint profitRate;        // 利润率: 100 - 奖金分成比例和

    function setPrizeRate(uint[] val) public onlyDev {
        require(val.length == 3);
        prizeRate.length = 3;
        uint sum = 100;
        for (uint i = 0; i < 3; i++) {
            prizeRate[i] = val[i];
            sum = sum.sub(val[i]);
        }
        require(sum > 0);   // 利润率要大于0
        profitRate = sum;
    }

    /// 利润分成
    address public dividePoolAddr;      // 分红池地址

    uint public divideRate = 40;    // 分红池分成比例
    uint public devRate = 50;            // 开发者分成比例
    uint public referRate = 5;          // 邀请返现比例
    uint public rankingRate = 5;         // 排行榜分成比例
    uint public referAmount;
    uint public rankAmount;
    uint public divideAmount;

    function setDividePool(address addr) public onlyDev {
        dividePoolAddr = addr;
    }

    function setProfitDivideRule(uint divide, uint dev, uint refer, uint ranking) public onlyDev {
        require(divide + dev + refer + ranking <= 100);
        divideRate = divide;
        devRate = dev;
        referRate = refer;
        rankingRate = ranking;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDev() {
        require(msg.sender == developer);
        _;
    }

    address public owner;
    address public developer;
    bool public isPause = true;
    
    function setPause(bool pause) public onlyDev {
        isPause = pause;
    }

    constructor() public {
        owner = msg.sender;
        developer = msg.sender;
        isPause = false;

        prizeRate.push(50);
        prizeRate.push(20);
        prizeRate.push(10);
        profitRate = 20;

        newTerm();
    }

    function newTerm() internal {
        termID++;
        Term storage info = termInfo[termID];
        info.startTime = now;
        info.startBlock = block.number;
        info.profitRate = profitRate;
        info.drawBlockGap = drawBlockGap;
        info.drawBlockNum = drawBlockNum;
        info.drawRankGap = drawRankGap;
        for (uint i = 0; i < prizeRate.length; i++ ) {
            info.prizeRate.push(prizeRate[i]);
        }
    }

    function setDev(address addr) public onlyOwner {
        require(address(0) != addr);
        developer = addr;
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw(address addr, uint amount) public onlyOwner {
        require(address(0) != addr);
        addr.transfer(amount);
    }

    /// user play data
    struct Receipt {
        uint start;
        uint end;
    }

    struct Term {
        uint startBlock;    // 开始时间
        uint startTime;     // 开始时间
        uint endBlock;      // 结束区块
        uint drawBlock;     // 开奖区块

        uint totalAmount;   // 本轮累计流水
        uint maxNumber;     // 最大彩票号码
        uint totalSpend;

        address endUser;    // 开奖用户
        address drawUser;   // 开奖用户

        // 开奖信息
        address[] winer;    // 获奖用户数组 0,1,2 分别对应第一，第二，第三名的用户地址
        uint[] winNumber;   // 开奖号码数据 0,1,2 分别对应第一，第二，第三名的号码
        uint[] prize;       // 奖金分配数据 0,1,2 分别对应第一，第二，第三名的奖金
        uint[] calcBlock;   // 计算开奖号码使用的区块开始号码, 分别对应第一，第二，第三名
        uint drawBlockGap;  // 本期开奖区块与结束区块的间隔
        uint drawBlockNum;  // 本期开奖所需的区块数
        uint drawRankGap;   // 本期开奖各名次的区块间隔
        bool drawState;     // 开奖状态, true: 已开奖; false: 未开奖
        uint profitRate;    //
        uint[] prizeRate;     //

        // 售卖记录
        uint[] sellIdx;     // 彩票售卖顺序
        mapping(address => Receipt[]) userNumbers;  // 用户的彩票购买记录
        mapping(uint => address) number2User;       // 彩票卖出顺序 => 购买用户地址
    }

    uint public termID;                     // 当前轮次
    mapping(uint => Term) public termInfo;  // 每轮次信息

    uint constant SUN = 1000000;
    uint public price = 50 * SUN;           // 单张彩票价格
    uint public endThreshold = 5000 * SUN;  // 单个轮次结束需要获得流水

    function setLottoryPrice(uint val) public onlyDev {
        require(val >= SUN);
        price = val;
    }

    function setEndThreshold(uint val) public onlyDev {
        require(val >= 100 * SUN && val <= 10000000 * SUN);
        endThreshold = val;
    }

    // event MineOK()

    function buy(address referrer) public payable {
        require(isPause == false);
        require(msg.value >= price, "not sufficient fee!");

        uint nums = msg.value / price;
        uint amount = price * nums;
        uint change = msg.value - amount;   // 找零

        Term storage info = termInfo[termID];

        uint endNumber = info.maxNumber + nums - 1;

        info.number2User[info.maxNumber] = msg.sender; // 记录用户购买的起始号码
        info.userNumbers[msg.sender].push(Receipt(info.maxNumber, endNumber));  // 记录用户购买的号码范围
        info.sellIdx.push(info.maxNumber); // 记录号码卖出的顺序

        if (change > 0) { // 找零
            msg.sender.transfer(change);
        }

        info.maxNumber += nums;
        info.totalAmount += amount;

        playCnt++;
        totalReceive = totalReceive + amount;

        emit LuckLottory(msg.sender, termID, info.maxNumber-nums, endNumber);

        if (address(0) != mineCtx) {
            MineIF(mineCtx).mine(msg.sender, developer, msg.value);
        }

        if (address(0) != referCtx && referRate > 0) {
            ReferIF(referCtx).refer.value(msg.value * info.profitRate * referRate / 10000)(msg.sender, msg.value, referrer);
            info.totalSpend = info.totalSpend + msg.value * info.profitRate * referRate / 10000;
            referAmount += msg.value * info.profitRate * referRate / 10000;
        }

        if (address(0) != rankCtx && rankingRate > 0) {
            RankingIF(rankCtx).ranking.value(msg.value * info.profitRate * rankingRate / 10000)(msg.sender, msg.value);
            info.totalSpend = info.totalSpend + msg.value * info.profitRate * rankingRate / 10000;
            rankAmount += msg.value * info.profitRate * rankingRate / 10000;
        }
        
        if (address(0) != dividePoolAddr && divideRate > 0) {
            DivideIF(dividePoolAddr).dividePay.value(msg.value * info.profitRate * divideRate / 10000)();
            divideAmount += msg.value * info.profitRate * divideRate;
        }
    }

    function end() public {
        Term storage info = termInfo[termID];
        require(info.totalAmount >= endThreshold);
        require(info.userNumbers[msg.sender].length > 0 || msg.sender == developer || msg.sender == owner);

        info.endUser = msg.sender;
        info.endBlock = block.number;

        uint drawBlock = block.number + info.drawBlockGap + info.drawRankGap * 2 + 20;
        emit TermEnd(termID, 1, drawBlock, info.drawBlockNum);
        info.calcBlock.push(drawBlock); // 第一名开奖区块

        drawBlock = drawBlock - info.drawRankGap;
        emit TermEnd(termID, 2, drawBlock, info.drawBlockNum);
        info.calcBlock.push(drawBlock); // 第二名开奖区块

        drawBlock = drawBlock - info.drawRankGap;
        emit TermEnd(termID, 3, drawBlock, info.drawBlockNum);
        info.calcBlock.push(drawBlock); // 第三名开奖区块

        newTerm();
    }

    function draw(uint id) public {
        require(id < termID && id > 0);

        Term storage info = termInfo[id];
        require(info.drawState == false);   // 还未开奖
        require(info.calcBlock[0] > 0 && info.calcBlock[0] <= block.number); // 最大开奖区块未到
        require(info.totalAmount - info.totalSpend > 0);

        info.drawState = true;
        info.drawUser = msg.sender;
        info.drawBlock = block.number;

        if (block.number - info.calcBlock[0] > 120) {
            info.calcBlock[0] = block.number - 20;
            info.calcBlock[1] = info.calcBlock[0] - info.drawRankGap;
            info.calcBlock[2] = info.calcBlock[1] - info.drawRankGap;
        }

        uint number;        // 开奖号码
        address winer;      // 中奖用户
        uint prize;         // 奖金
        for (uint i = 0; i < 3; i++) {
            number = _drawNumber(info.calcBlock[i]-20, info.drawBlockNum, info.maxNumber);
            winer = _getOwner(number, id);
            prize = info.totalAmount * info.prizeRate[i] / 100;

            info.winNumber.push(number);
            info.winer.push(winer);
            info.prize.push(prize);

            emit Draw(winer, number, prize, id, i+1);
            winer.transfer(prize);
            info.totalSpend = info.totalSpend + prize;
            totalBonus = totalBonus + prize;
        }

        prize = info.totalAmount - info.totalSpend;
        if (prize >= price) {
            info.endUser.transfer(price);
            info.totalSpend = info.totalSpend + price;
        }

        prize = info.totalAmount - info.totalSpend;
        if (prize >= price) {
            info.drawUser.transfer(price);
            info.totalSpend = info.totalSpend + price;
        }

        prize = info.totalAmount - info.totalSpend;
        if (prize > 0) {
            owner.transfer(price);
            info.totalSpend = info.totalSpend + prize;
        }
    }

    function _drawNumber(uint start, uint count, uint range) internal view returns(uint ret) {
        //return (now + start + count) % range;
        for (uint i = 0; i < count; i++) {
            ret += uint(keccak256(abi.encodePacked(blockhash(start - i))));
        }
        ret = ret % range;
        return ret;
    }

    function _getOwner(uint num, uint id) internal view returns (address) {
        Term storage info = termInfo[id];

        uint mid;
        uint left = 0;
        uint right = info.sellIdx.length - 1;

        while (left <= right) {
            mid = (left + right) / 2;

            if (info.sellIdx[mid] > num) {
                right = mid.sub(1);
                continue;
            }
            if (info.sellIdx[mid] == num) {
                break;
            }
            if (info.sellIdx[mid] < num) {
                if (mid + 1 >= info.sellIdx.length) {
                    break;
                }
                if (info.sellIdx[mid + 1] > num) {
                    break;
                }
                left = mid.add(1);
            }
        }

        uint number = info.sellIdx[mid]; // 卖出的号码
        return info.number2User[number]; // 买号码的人
    }

    function getTermNumberOwner(uint number, uint id) public view returns(address) {
        require(id <= termID && id > 0);

        Term storage info = termInfo[id];
        if (number >= info.maxNumber) {
            return address(0);
        }

        return _getOwner(number, id);
    }

    function getTermUserNumbers(address addr, uint id) public view returns(uint[] memory, uint[] memory) {
        require(id <= termID);

        if (msg.sender != addr) {
            require(msg.sender == owner || msg.sender == developer, "invalid operation");
        }

        if (id == 0) {
            id = termID;
        }

        Term storage info = termInfo[id];

        if (info.userNumbers[addr].length == 0) {
            return;
        }

        uint[] memory starts = new uint[](info.userNumbers[addr].length);
        uint[] memory ends = new uint[](info.userNumbers[addr].length);

        for (uint i = 0; i < info.userNumbers[addr].length; i++) {
            starts[i] = info.userNumbers[addr][i].start;
            ends[i] = info.userNumbers[addr][i].end;
        }
        return (starts, ends);
    }

    function getTermResult(uint id) public view returns (uint[] memory, address[] memory, uint[] memory, uint[] memory, uint[] memory) {
        require(id > 0 && id <= termID);

        Term storage info = termInfo[id];

        uint[] memory winNumber = new uint[](info.winNumber.length);
        address[] memory winer = new address[](info.winer.length);
        uint[] memory prize = new uint[](info.prize.length);
        uint[] memory calcBlock = new uint[](info.calcBlock.length);
        uint[] memory pr = new uint[](info.prizeRate.length);

        for (uint i = 0; i < info.winNumber.length; i++) {
            winNumber[i] = info.winNumber[i];
            winer[i] = info.winer[i];
            prize[i] = info.prize[i];
        }

        for (i = 0; i < info.calcBlock.length; i++) {
            calcBlock[i] = info.calcBlock[i];
        }

        for (i = 0; i < info.prizeRate.length; i++) {
            pr[i] = info.prizeRate[i];
        }

        return (
            winNumber,
            winer,
            prize,
            calcBlock,
            pr
        );
    }

    function checkin() public payable {}
}
