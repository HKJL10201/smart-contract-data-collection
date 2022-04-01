pragma solidity ^0.4.25;

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

interface ReferIF {
    function refer(address user, uint amount, address referrer) external payable;
}

contract Test {

    address public referIF;

    function setReferIF(address addr) public {
        referIF = addr;
    }

    function play(address referrer) public payable {
        ReferIF(referIF).refer.value(msg.value)(msg.sender, msg.value,  referrer);
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

contract UserID {

    mapping(address => uint) public user2id;
    mapping(uint => address) public id2user;

    uint constant minID = 0;
    uint public maxID = minID;

    function getID(address addr) internal returns (uint) {
        uint id = user2id[addr];
        if (id == minID) {
            maxID++;
            id = maxID;
            user2id[addr] = id;
            id2user[id] = addr;
        }
        return id;
    }

    function findID(address addr) public view returns (uint) {
        uint id = user2id[addr];
        return id;
    }
}

contract Refer is UserID, Ownable, ReferIF {
    using SafeMath for uint;

    struct UserGameCount {
        uint amount;
        uint count;
    }

    struct Info {
        mapping(address => UserGameCount) game;
        address referrer;
        uint amount;
        uint count;

        // info as referrer
        uint income;
        uint withdraw;

        mapping(uint => uint) levelCnt;
        mapping(uint => uint) levelAmount;
    }

    mapping(address => Info) _info;

    bool bindWholeLife = true;

    function setBindWholeLife(bool wholeLife) public onlyOwner {
        bindWholeLife = wholeLife;
    }

    uint[] referRate;
    function setReferRate(uint[] rate) public onlyOwner {
        referRate = rate;
    }
    
    address public dev;

    constructor() public {
        // init refer feedback rate;
        referRate.push(60);
        referRate.push(30);
        referRate.push(10);
        
        dev = msg.sender;
    }
    
    function setDev(address addr) public onlyOwner {
        dev = addr;
    }
    
    modifier onlyDev {
        require(msg.sender == dev);
        _;
    }

    uint public gameID;
    struct GameInfo {
        uint amount;
        uint count;
        uint income;
        uint id;
        bool ok;
    }
    mapping(address => GameInfo) gameInfo;
    mapping(uint => address) id2game;

    function setGame(address game, bool ok) public onlyOwner {
        GameInfo storage info = gameInfo[game];
        info.ok = ok;
        if (info.id == 0) {
            gameID++;
            info.id = gameID;
            id2game[gameID] = game;
        }
    }

    modifier onlyGame {
        if (gameInfo[msg.sender].ok) {
            _;
        } else {
            income = income.add(msg.value);
        }
    }

    function bonus() public view returns (uint, uint) {
        Info storage info = _info[msg.sender];
        return (info.income, info.withdraw);
    }

    function referrerInfo() public view returns (address, uint, uint, uint, uint, uint[] memory, uint[] memory) {
        Info storage info = _info[msg.sender];

        uint[] memory levelCnt = new uint[](referRate.length);
        uint[] memory levelAmount = new uint[](referRate.length);

        for (uint i = 0; i < referRate.length; i++) {
            levelCnt[i] = info.levelCnt[i];
            levelAmount[i] = info.levelAmount[i];
        }

        return (info.referrer, info.income, info.withdraw, info.amount, info.count, levelCnt, levelAmount);
    }

    function referrerDetail(address user) public view onlyDev returns (address, uint, uint, uint, uint, address[] memory, uint[] memory, uint[] memory) {
        Info storage info = _info[user];

        address[] memory gameAddr = new address[](gameID);
        uint[] memory gameAmount = new uint[](gameID);
        uint[] memory gameCount = new uint[](gameID);

        for (uint i = 1; i <= gameID; i++) {
            gameAddr[i-1] = id2game[i];
            gameAmount[i-1] = info.game[id2game[i]].amount;
            gameCount[i-1] = info.game[id2game[i]].count;
        }

        return (info.referrer, info.income, info.withdraw, info.amount, info.count, gameAddr, gameAmount, gameCount);
    }
    
    function batchGetReferrerInfo(uint start, uint end) public view onlyDev returns (address[] memory, uint[] memory, uint[] memory) {
        if (start < minID) {
            start = minID;
        }
        if (start + 99 < end) {
            end = start+99;
        }
        if (end > maxID) {
            end = maxID;
        }
        
        address[] memory addrs = new address[](end-start+1);
        uint[] memory amounts = new uint[](end-start+1);
        uint[] memory counts = new uint[](end-start+1);
        
        for (uint i = start; i <= end; i++) {
            addrs[i] = id2user[i];
            amounts[i] = _info[addrs[i]].amount;
            counts[i] = _info[addrs[i]].count;
        }
        
        return (addrs, amounts, counts);
    }

    function gameDetail(uint id) public view onlyDev returns (uint, uint, uint) {
        if (id <= 0 || id > gameID) {
            return (0, 0, 0);
        }
        address game = id2game[id];
        GameInfo storage info = gameInfo[game];

        return (info.amount, info.count, info.income);
    }

    function withdraw() public {
        Info storage info = _info[msg.sender];
        require(info.income > 0, "no balance left");
        msg.sender.transfer(info.income);
        info.withdraw = info.withdraw + info.income;
        spend = spend + info.income;
        info.income = 0;
    }

    function withdrawDev(address addr) public onlyDev {
        require(addr != address(0));
        addr.transfer(income);
        withdrawAmount = withdrawAmount.add(income);
        income = 0;
    }

    function withdrawOwner(address addr, uint amount) public onlyOwner {
        require(addr != address(0));
        addr.transfer(amount);
    }

    event ReferEvent(address, uint, address, uint, address);

    uint public spend;
    uint public total;
    uint public income;
    uint public withdrawAmount;
    function refer(address user, uint amount, address referrer) external payable onlyGame {
        if (msg.value == 0) {
            return;
        }
        total = total.add(msg.value);
        // emit ReferEvent(msg.sender, msg.value, user, amount, referrer);
        if (user == referrer) { // do not allow self refer
            return;
        }
        if (address(0) == referrer) {
            return;
        }

        getID(user);
        getID(referrer);

        bool bFirst = false;
        Info storage info = _info[user];
        if (bindWholeLife) {
            if (address(0) == info.referrer) {
                info.referrer = referrer;
                bFirst = true;
            }
        } else {
            info.referrer = referrer;
        }
        gameInfo[msg.sender].amount = gameInfo[msg.sender].amount + amount;
        gameInfo[msg.sender].count++;
        gameInfo[msg.sender].income = gameInfo[msg.sender].income + msg.value;
        info.game[msg.sender].amount = info.game[msg.sender].amount + amount;
        info.game[msg.sender].count++;

        address loopReferrer = info.referrer;
        uint totalRate = 100;

        for (uint i = 0; i < referRate.length; i++) {
            if (loopReferrer == address(0)) {
                break;
            }

            _info[loopReferrer].amount += amount;
            _info[loopReferrer].levelAmount[i] += amount;
            if (bFirst) {
                _info[loopReferrer].count++;
                _info[loopReferrer].levelCnt[i]++;
            }

            if (totalRate < referRate[i]) {
                break;
            }
            totalRate = totalRate - referRate[i];
            _info[loopReferrer].income = _info[loopReferrer].income + msg.value * referRate[i] / 100;

            loopReferrer = _info[loopReferrer].referrer;
        }
        income = income.add(msg.value * totalRate / 100);
    }
}
