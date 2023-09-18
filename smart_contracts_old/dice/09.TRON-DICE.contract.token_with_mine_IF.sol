pragma solidity ^0.4.25;

interface Mine {
    function mine(address user, address dev, uint amount) external;
}

interface ITRC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IApproveAndCallFallback {
    function receiveApproval(address _from, uint _value, address _token, bytes _data) external;
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

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


contract BDC is ITRC20, Ownable, Mine {
    using SafeMath for uint;

    event Lock(address indexed owner, uint value);
    event Unlock(address indexed owner, uint value);
    event Unfreeze(address indexed owner, uint value);

    string public symbol = "BDC";
    string public name = "BDC Token";
    uint8 constant public decimals = 6;
    uint private _totalSupply = 100 * 100000000 * 10 ** uint(decimals);

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allow;
    mapping(address => bool) private _whiteList;

    constructor () public {
        _balance[msg.sender] = _totalSupply;
        _whiteList[msg.sender] = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /// management
    bool authorizeMode = true;

    function setAuthorizeMode(bool state) public onlyOwner {
        authorizeMode = state;
    }

    function authorizeTransfer(address addr, bool ok) public onlyOwner {
        _whiteList[addr] = ok;
    }

    function check(address from, address to) internal view returns (bool) {
        if (!authorizeMode) {
            return true;
        }
        return (_whiteList[from] || _whiteList[to]);
    }
    /// end management

    /// mine
    uint public minePrice = 100;
    uint public mineDevRate = 10;

    function setMinePrice(uint price) public onlyOwner {
        require(price>0);
        minePrice = price;
    }

    function setMineDevRate(uint rate) public onlyOwner {
        mineDevRate = rate;
    }

    uint public mineAmount;
    uint public mineCount;
    struct MinerInfo {
        uint id;
        bool ok;
        bool checkPrice;
        bool checkRate;


        uint minePrice;
        uint mineDevRate;
        uint amount;
        uint count;
    }
    mapping(address => MinerInfo) _minerInfo;
    mapping(uint => address) _minerID;
    uint public minerID = 0;

    function addMiner(address miner, uint price, uint rate) public onlyOwner {
        require(_minerInfo[miner].id == 0, "miner exist");
        minerID++;
        _minerID[minerID] = miner;

        _minerInfo[miner] = MinerInfo(
            minerID,
            true,
            true,
            true,
            price,
            rate,
            0,
            0);

    }

    modifier onlyMiner {
        require(_minerInfo[msg.sender].id > 0, "invalid miner");
        _;
    }

    function setMinerInfo(address miner, bool ok, uint price, uint rate, bool checkPrice, bool checkRate) public onlyOwner {
        require(_minerInfo[miner].id > 0, "invalid miner");
        MinerInfo storage info = _minerInfo[miner];
        info.ok = ok;
        info.minePrice = price;
        info.mineDevRate = rate;
        info.checkPrice = checkPrice;
        info.checkRate = checkRate;
    }

    function getMinerInfo(uint id) public view onlyOwner returns(address, uint, bool, bool, bool, uint, uint, uint, uint) {
        require(_minerID[id] != address(0), "invalid miner");
        MinerInfo storage info = _minerInfo[_minerID[id]];

        return (_minerID[id], info.id, info.ok, info.checkPrice, info.checkRate, info.minePrice, info.mineDevRate, info.amount, info.count);
    }

    function mine(address user, address dev, uint amount) external onlyMiner  {
        MinerInfo storage info = _minerInfo[msg.sender];
        if (info.minePrice == 0 || !info.ok) {
            return;
        }
        uint price = info.minePrice;
        if (info.checkPrice && price < minePrice) {
            price = minePrice;
        }
        uint devRate = info.mineDevRate;
        if (info.checkRate && devRate > mineDevRate) {
            devRate = mineDevRate;
        }

        uint userMineAmount = amount / minePrice;
        uint devMineAmount = userMineAmount * mineDevRate / 100;
        info.amount = info.amount + userMineAmount + devMineAmount;
        info.count++;
        mineAmount = mineAmount + userMineAmount + devMineAmount;
        mineCount++;

        if (_balance[owner] >= userMineAmount) {
            _transfer(owner, user, userMineAmount);
        }
        if (_balance[owner] >= devMineAmount) {
            _transfer(owner, dev, devMineAmount);
        }
    }
    /// end mine

    /// uid
    mapping(address => uint) private _user2id;
    mapping(uint => address) private _id2user;
    uint public maxUID = 0;

    function getuid(address addr) internal returns (uint uid) {
        uid = _user2id[addr];
        if (0 == uid) {
            maxUID++;
            uid = maxUID;
            _user2id[addr] = uid;
            _id2user[uid] = addr;
        }
        return uid;
    }

    function finduid(address addr) internal view returns (uint uid) {
        uid = _user2id[addr];
        require(uid != 0, "invalid lock user");
        return uid;
    }
    /// uid

    /// freeze
    uint public totalLock;
    uint public totalFreeze;
    uint public totalOption;
    uint constant public LOCK_TIME = 3 days;
    uint constant public FREEZE_TIME = 1 days;
    mapping(address => uint) private _unlockTime;
    mapping(address => uint) private _unfreezeTime;
    mapping(uint => uint) private _lock;
    mapping(address => uint) private _freeze;
    mapping(address => OptionInfo) private _option;

    struct OptionInfo {
        uint maxIdx;
        uint total;
        uint cashCnt;
        mapping(uint => Option) options;
    }

    struct Option {
        uint unlockTime;
        uint amount;
        address sender;
        uint cashingTime;
    }

    function payOption(address spender, uint amount, uint lockDay) public returns (bool) {
        require(check(msg.sender, spender));
        require(address(0) != spender);
        require(_balance[msg.sender] >= amount);
        require(lockDay > 0);

        OptionInfo storage oi = _option[spender];

        _balance[msg.sender] = _balance[msg.sender].sub(amount);

        oi.total = oi.total.add(amount);
        oi.options[oi.maxIdx] = Option(block.timestamp + lockDay*24*60*60, amount, msg.sender, 0);
        oi.maxIdx++;
        totalOption = totalOption.add(amount);

        return true;
    }

    function cashingOption(uint start, uint end) public returns (uint) {
        require(end.sub(start) < 100);
        OptionInfo storage oi = _option[msg.sender];
        require(oi.total > 0);
        if (end > oi.maxIdx) {
            end = oi.maxIdx;
        }

        uint cashTotal = 0;
        for (uint i = start; i < end; i++) {
            if (oi.options[i].unlockTime <= block.timestamp && oi.options[i].cashingTime == 0 && oi.options[i].amount > 0) {
                oi.total = oi.total.sub(oi.options[i].amount);
                oi.options[i].cashingTime = block.timestamp;
                _balance[msg.sender] = _balance[msg.sender].add(oi.options[i].amount);
                emit Transfer(oi.options[i].sender, msg.sender, oi.options[i].amount);
                cashTotal = cashTotal.add(oi.options[i].amount);
                oi.cashCnt++;

                totalOption = totalOption.sub(oi.options[i].amount);
            }
        }
    }

    function options(address addr) public view returns (uint totalAmount, uint totalCnt, uint cashCnt) {
        require(address(0) != addr);
        OptionInfo storage oi = _option[addr];

        return (oi.total, oi.maxIdx, oi.cashCnt);
    }

    function optionsDetail(address addr, uint start, uint end) public view returns (uint[] memory, uint[] memory, address[] memory, uint[] memory) {
        require(address(0) != addr);
        require(end.sub(start) <= 100);
        OptionInfo storage oi = _option[addr];

        if (end > oi.maxIdx) {
            end = oi.maxIdx;
        }
        require(end.sub(start) > 0);

        uint[] memory unlockTimes = new uint[](end-start);
        uint[] memory amounts = new uint[](end-start);
        address[] memory senders = new address[](end-start);
        uint[] memory cashTimes = new uint[](end-start);

        uint idx = 0;
        for (uint i = start; i < end; i++) {
            unlockTimes[idx] = oi.options[i].unlockTime;
            amounts[idx] = oi.options[i].amount;
            senders[idx] = oi.options[i].sender;
            cashTimes[idx] = oi.options[i].cashingTime;
            idx++;
        }

        return (
            unlockTimes,
            amounts,
            senders,
            cashTimes
            );
    }

    function lockedAmount(address addr) public view returns (uint) {
        if (_unlockTime[addr] == 0) {
            return 0;
        }
        uint uid = finduid(addr);
        return _lock[uid];
    }

    function lock(uint amount) external returns (bool) {
        require(amount > 0, "lock amount should > 0");
        require(_balance[msg.sender] >= amount, "balance insufficient");
        uint uid = getuid(msg.sender);

        _balance[msg.sender] = _balance[msg.sender].sub(amount);
        _lock[uid] = _lock[uid].add(amount);
        _unlockTime[msg.sender] = block.timestamp + LOCK_TIME;
        totalLock = totalLock.add(amount);

        emit Lock(msg.sender, amount);

        return true;
    }

    function unlockTime(address addr) public view returns (uint) {
        return _unlockTime[addr];
    }

    function unlock(uint amount) external returns (bool) {
        require(_unlockTime[msg.sender] <= block.timestamp, "unlock time limit");
        uint uid = finduid(msg.sender);

        uint unlockAmount = _lock[uid];
        require(amount <= unlockAmount, "locked amount insufficient");

        if (0 < amount) {
            unlockAmount = amount;
        }

        _lock[uid] = _lock[uid].sub(unlockAmount);
        _freeze[msg.sender] = _freeze[msg.sender].add(unlockAmount);
        _unfreezeTime[msg.sender] = block.timestamp + FREEZE_TIME;
        totalLock = totalLock.sub(unlockAmount);
        totalFreeze = totalFreeze.add(unlockAmount);

        emit Unlock(msg.sender, unlockAmount);

        return true;
    }

    function fronzenAmount(address addr) public view returns (uint) {
        require(_unfreezeTime[addr] > 0);
        return _freeze[addr];
    }

    function unfreezeTime(address addr) public view returns (uint) {
        return _unfreezeTime[addr];
    }

    function unfreeze(uint amount) external returns (bool) {
        require(_unfreezeTime[msg.sender] <= block.timestamp, "unfreeze time limit");
        require(amount <= _freeze[msg.sender], "fronze amount insufficient");

        uint unfreezeAmount = _freeze[msg.sender];
        if (0 < amount) {
            unfreezeAmount = amount;
        }
        _freeze[msg.sender] = _freeze[msg.sender].sub(unfreezeAmount);
        _balance[msg.sender] = _balance[msg.sender].add(unfreezeAmount);
        totalFreeze = totalFreeze.sub(unfreezeAmount);

        emit Unfreeze(msg.sender, unfreezeAmount);

        return true;
    }

    function batchGetLockAmount(uint start, uint end) public view returns (uint[] memory) {
        require(start < end && end.sub(start) <= 100);

        if (end > maxUID) {
            end = maxUID;
        }

        uint[] memory lockAmount = new uint[](end-start+1);
        uint idx = 0;
        for (uint i = start; i <=end; i++) {
            lockAmount[idx] = _lock[i];
            idx++;
        }

        return lockAmount;
    }

    function batchGetLockAddr(uint start, uint end) public view returns (address[] memeory) {
        require(start < end && end.sub(start) <= 100);

        if (end > maxUID) {
            end = maxUID;
        }

        address[] memory addrs = new address[](end-start+1);
        uint idx = 0;
        for (uint i = start; i <= end; i++) {
            addrs[idx] = _id2user[i];
            idx++;
        }

        return addrs;
    }
    /// end freeze

    /// TRC20 IF
    function totalSupply () public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view returns (uint) {
        return _balance[owner];
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allow[owner][spender];
    }

    function transfer(address to, uint value) external returns (bool) {
        require(check(msg.sender, to));
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        require(spender != address(0));
        require(check(msg.sender, spender));

        _allow[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(check(msg.sender, to));

        _allow[from][msg.sender] = _allow[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allow[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        require(spender != address(0));
        require(check(msg.sender, spender));

        _allow[msg.sender][spender] = _allow[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allow[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        require(spender != address(0));
        require(check(msg.sender, spender));

        _allow[msg.sender][spender] = _allow[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allow[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint value) private {
        require(to != address(0));

        _balance[from] = _balance[from].sub(value);
        _balance[to] = _balance[to].add(value);
        emit Transfer(from, to, value);
    }

    function burn(uint value) external {
        _totalSupply = _totalSupply.sub(value);
        _balance[msg.sender] = _balance[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

    function approveAndCall(address spender, uint value, bytes data) external returns (bool) {
        require(check(msg.sender, spender));

        _allow[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        IApproveAndCallFallback(spender).receiveApproval(msg.sender, value, address(this), data);
        return true;
    }

    function() external payable {
        revert();
    }

    function transferAnyTRC20Token(address tokenAddress, uint value) external onlyOwner returns (bool) {
        return ITRC20(tokenAddress).transfer(owner, value);
    }
}
