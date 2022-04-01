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

library SafeMath {
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract DiceGame is Ownable {
    using SafeMath for uint;

    event Play(address indexed addr, uint indexed index, uint point, uint pay, bool up);
    event Win(address indexed player, uint indexed playIdx, uint pay, uint point, uint result, uint prize, bool up);
    event Lose(address indexed player, uint indexed playIdx, uint pay, uint point, uint result, bool up);

    uint constant SUN = 1000000;
    uint minPay = 10 * SUN;
    uint maxPay = 10000 * SUN;

    uint feedbackRate = 97;
    uint minPoint = 2;
    uint maxPoint = 96;
    uint RetainRate = 100 - feedbackRate;
    uint public devRate = 20;
    uint public refRate = 10;
    uint public rankRate = 10;
    uint public CostDev = RetainRate * devRate;
    uint public CostRef = RetainRate * refRate;
    uint public CostRank = RetainRate * rankRate;

    function setDevRate(uint rate) public onlyDev {
        devRate = rate;
        divideRate = RetainRate * (uint(100).sub(devRate).sub(refRate).sub(rankRate));
    }

    function setRefRate(uint rate) public onlyDev {
        refRate = rate;
        divideRate = RetainRate * (uint(100).sub(devRate).sub(refRate).sub(rankRate));
    }

    function setRankRate(uint rate) public onlyDev {
        rankRate = rate;
        divideRate = RetainRate * (uint(100).sub(devRate).sub(refRate).sub(rankRate));
    }

    address public developer;

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

    modifier onlyDev() {
        require(msg.sender == developer);
        _;
    }

    constructor() public {
        owner = msg.sender;
        developer = msg.sender;
    }

    function setDev(address _dev) public onlyOwner() {
        developer = _dev;
    }

    function setPointRange(uint _min, uint _max) public onlyDev {
        require(_min < _max && _min >= 1 && _max < feedbackRate);
        minPoint = _min;
        maxPoint = _max;
    }

    function setPayRange(uint _min, uint _max) public onlyDev {
        require(_min < _max);
        minPay = _min;
        maxPay = _max;
    }

    function withdraw(address addr, uint amount) public onlyOwner {
        addr.transfer(amount);
    }

        /// divide of retain money
    struct DivideInfo {
        address addr;
        uint rate;
        uint amount;
    }

    mapping(address => uint) divider;
    mapping(uint => DivideInfo) divideMap;
    uint divideLen;
    uint public divideRate = RetainRate * (uint(100).sub(devRate).sub(refRate).sub(rankRate));
    uint public divideRateAll = 0;

    modifier onlyDivider {
        require(divider[msg.sender] > 0, "invalid divider");
        _;
    }

    function addDivider(address addr, uint rate) public onlyDev {
        require(divideRateAll+rate <= 100);
        require(address(0) != addr);

        divideLen++;
        divideRateAll = divideRateAll + rate;
        divideMap[divideLen] = DivideInfo(addr, rate, 0);
        divider[addr] = divideLen;
    }

    function removeDivider(address addr) public onlyDev {
        require(divider[addr] > 0, "invalid divider");

        uint idx = divider[addr];
        require(divideMap[idx].addr == addr, "divider info not match");

        divideRateAll = divideRateAll - divideMap[idx].rate;
        delete divideMap[idx];
        divideMap[idx] = divideMap[divideLen-1];
        delete divideMap[divideLen-1];
        divideLen--;

        delete divider[addr];
        divider[divideMap[idx].addr] = idx;
    }

    function dividePrize() public view onlyDivider returns (uint) {
        return divideMap[divider[msg.sender]].amount;
    }

    function dividerWithdraw(address addr, uint amount) public onlyDivider {
        require(address(0) != addr, "invalid divider withdraw address");

        uint idx = divider[msg.sender];

        DivideInfo storage info = divideMap[idx];
        require(info.amount >= amount, "invalid divider withdraw amount");
        info.amount = info.amount - amount;
        addr.transfer(amount);
    }

    function divideMoney(uint amount) internal {
        for (uint i = 0; i < divideLen; i++) {
            divideMap[i].amount = divideMap[i].amount + (amount * divideMap[i].rate / 100);
        }
    }
    /// end divide

    /// bidding logic
    uint public resultIdx = 0;
    uint public totalPay = 0;
    uint public totalPrize = 0;

    struct Ticket {
        address addr;
        uint pay;
        uint point;
        uint result;
        uint prize;
        bool up; // true: roll up; false: roll down
    }

    Ticket[] tickets;

    /// play
    /// args
    ///     uint _point:
    ///     uint _ref
    ///     bool _up
    function play(uint point_, address ref_, bool up_) public payable {
        require(msg.value >= minPay && msg.value <= maxPay, "invalid fee");
        if (!up_) {
            require(point_ >= minPoint && point_ <= maxPoint, "invalid roll down point");
        } else {
            require(point_ >= 100 - maxPoint && point_ <= 100 - minPoint, "invlaid roll up point");
        }

        Ticket memory ticket = Ticket(msg.sender, msg.value, point_, 0, 0, up_);
        tickets.push(ticket);
        emit Play(msg.sender, tickets.length-1,  point_, msg.value, up_);

        totalPay += msg.value;

        MineIF(mineCtx).mine(msg.sender, developer, msg.value);

        developer.transfer(msg.value * CostDev / 10000);

        ReferIF(referCtx).refer.value(msg.value * CostRef / 10000)(msg.sender, msg.value, ref_);
        RankingIF(rankCtx).ranking.value(msg.value * CostRank / 10000)(msg.sender, msg.value);

        divideMoney(msg.value * divideRate / 10000);
    }

    function draw(uint _point, uint index) public onlyDev returns (uint) {
        require(resultIdx < tickets.length);
        require(index <= resultIdx);

        Ticket storage ticket = tickets[index];
        require(ticket.result == 0, "drawed");
        ticket.result =  _point > 100 ? ticket.point : _point;

        if (!ticket.up) {
            if (ticket.result < ticket.point) {
                ticket.prize = ticket.pay * feedbackRate / ticket.point;
                emit Win(ticket.addr, resultIdx, ticket.pay, ticket.point, ticket.result, ticket.prize, ticket.up);
                address(ticket.addr).transfer(ticket.prize);
                totalPrize = totalPrize.add(ticket.prize);
            } else {
                emit Lose(ticket.addr, resultIdx, ticket.pay, ticket.point, ticket.result, ticket.up);
            }
        } else {
            if (ticket.result > ticket.point) {
                ticket.prize = ticket.pay * feedbackRate / (100 - ticket.point);
                emit Win(ticket.addr, resultIdx, ticket.pay, ticket.point, ticket.result, ticket.prize, ticket.up);
                address(ticket.addr).transfer(ticket.prize);
                totalPrize = totalPrize.add(ticket.prize);
            } else {
                emit Lose(ticket.addr, resultIdx, ticket.pay, ticket.point, ticket.result, ticket.up);
            }
        }

        resultIdx++;

        return (resultIdx);
    }

    function info(uint _index) public view returns (address, uint, uint, bool, uint, uint) {
        require(_index < tickets.length);
        Ticket storage ticket = tickets[_index];
        return (ticket.addr, ticket.point, ticket.pay, ticket.up, ticket.result, ticket.prize);
    }

    function index() public view returns (uint, uint) {
        return (tickets.length, resultIdx);
    }

    /// end game
}
