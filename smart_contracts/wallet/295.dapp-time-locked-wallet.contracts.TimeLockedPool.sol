pragma solidity ^0.4.18;


contract Miner {
    function set(uint64 start, uint32 lifespan, address coinbase, bytes32 vrfVerifier, bytes32 voteVerifier) public returns(bool);
}

contract TimeLockedPool {
    uint constant precision = 10000000;
    uint constant maxOwner = 100;

    address public creator;
    address public manager;

    uint64 public timeToStartUnlocking;
    uint64 public timeInterval;
    uint64 public numInterval;
    uint64 public lastUnlockTime;

    uint public totalWithdrawals;

    address[] public owners;
    mapping(address => uint) public proportions;

    event Deposit(address sender,uint256 value);
    event Unlocked(uint256 value);
    event TransferProportion(address from,address to, uint value);
    event CreatorReplaced(address creator,address newCreator);
    event MinerRegistered(address bywho);

    event Revocation(address _manager,uint _value);
    event ManagerReplaced(address manager,address newManager);

    modifier notNull(address addr) {
        require(addr != 0);
        _;
    }
    modifier onlyOwner {
        require(proportions[msg.sender] != 0);
        _;
    }
    modifier onlyCreator {
        require(msg.sender == creator);
        _;
    }
    modifier creatorOrOwner {
        require(proportions[msg.sender] != 0 || msg.sender == creator);
        _;
    }
    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }

    constructor(address _owner, address _creator, address _manager, uint64 start, uint64 interval, uint64 _numInterval) public notNull(_owner) notNull(_creator) {
        require(_numInterval > 0);
        require(interval > 0);

        creator = _creator;
        manager = _manager; // if 0x0, disable revoke function

        timeToStartUnlocking = start;
        timeInterval = interval;
        numInterval = _numInterval;

        owners.push(_owner);
        proportions[_owner] = 100 * precision;
    }

    function replaceCreator(address _newCreator) onlyCreator notNull(_newCreator) public returns(bool) {
        creator = _newCreator;
        emit CreatorReplaced(msg.sender, _newCreator);
        return true;
    }

    function replaceManager(address newManager) onlyManager public returns(bool){
        manager = newManager;
        emit ManagerReplaced(msg.sender, newManager);
        return true;
    }

    function transferProportion(address to, uint prop) public returns(bool){
        require(to != 0x0);
        require(prop > 0);
        require(proportions[msg.sender] >= prop);
        require(msg.sender != to);

        proportions[msg.sender] -= prop;
        // remove zero proportion owner
        if (proportions[msg.sender] == 0) {
            remove(owners, msg.sender);
        }

        // add new owner
        if (proportions[to] == 0) {
            require(owners.length < maxOwner);
            owners.push(to);
        }
        proportions[to] += prop;
        assert(proportions[to] >= prop); // check overflow

        emit TransferProportion(msg.sender, to, prop);
        return true;
    }

    // [0, numInterval]
    function timeToInterval(uint64 t) public view returns(uint) {
        if (t < timeToStartUnlocking) {
            return 0;
        }
        uint id = (t - timeToStartUnlocking) / timeInterval;
        if (id > numInterval) {
            id = numInterval;
        }
        return id;
    }

    function amountToUnlock(uint64 currTime) public view returns(uint) {
        // already unlocked before
        if(currTime <= lastUnlockTime) {
            return 0;
        }

        // already unlocked all
        uint lastInterval = timeToInterval(lastUnlockTime);
        if (lastInterval >= numInterval) {
            return address(this).balance;
        }

        // not start unlocking or already unlocked before
        uint currInterval = timeToInterval(currTime);
        if (currInterval <= lastInterval) {
            return 0;
        }

        uint leftInterval = numInterval - lastInterval;
        uint amount = address(this).balance * (currInterval - lastInterval) / leftInterval;
        return amount;
    }

    function unlock() public creatorOrOwner returns(uint) {
        uint amount = amountToUnlock(uint64(now));
        if (amount == 0) {
            return 0;
        }
        assert(amount <= address(this).balance);

        lastUnlockTime = uint64(now); //critical update

        totalWithdrawals += amount;

        // 除第一个人（必定存在）外按比例分配，第一个人分配剩余部分，以避免四舍五入造成的遗留；因此，这里要求按比例分配时，只舍不入。
        uint left = amount;
        for(uint i = 1; i < owners.length; i++) {
            address owner = owners[i];
            uint prop = proportions[owner];
            uint num = amount * prop / 100 / precision;
            require(num <= left);
            left = left - num;
            owner.transfer(num);
        }
        owners[0].transfer(left);

        emit Unlocked(amount);

        return amount;
    }

    function() public onlyCreator payable {
        require(msg.value > 0);
        emit Deposit(msg.sender, msg.value);
    }

    function revoke(uint _value) onlyManager public returns(bool){
        if (msg.sender == 0x0) {
            return false;
        }
        require(_value <= address(this).balance);
        msg.sender.transfer(_value);

        emit Revocation(msg.sender,_value);
        return true;
    }


    function registerMiner(uint64 start,uint32 lifespan,bytes32 vrfVerifier,bytes32 voteVerifier) public creatorOrOwner returns(bool suc){
        suc = Miner(0x1000000000000000000000000000000000000002).set(start, lifespan, address(this), vrfVerifier,voteVerifier);
        if(suc){
            emit MinerRegistered(msg.sender);
        }
        return suc;
    }

    /**
     * internal functions
     */

    function remove(address[] storage list,address item) internal returns(uint affected){
        for(uint i = 0; i < list.length; i++){
            if(list[i] == item){
                list[i] = list[list.length-1];
                list.length--;
                affected++;
                break;
            }
        }
        return affected;
    }
}
