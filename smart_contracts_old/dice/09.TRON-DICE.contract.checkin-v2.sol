pragma solidity ^0.4.25;

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

contract Checkin is Ownable {

    using SafeMath for uint;

    mapping(address => bool) private _whiteList;//save address list that can withdraw his bonus

    /// authorze
    bool authorizeMode = true;
    
    function setAuthorizeMode(bool state) public onlyOwner {
        authorizeMode = state;
    }
    
    function setPrivilege(address addr, bool ok) public onlyOwner {
        _whiteList[addr] = ok;
    }
    
    function check(address to) internal view returns (bool) {
        if (!authorizeMode) {
            return true;
        }
        return (_whiteList[to]);
    }
    /// end authorize

    struct Info {
        uint totalCnt;
        uint continuousCnt;
        uint latestCheckinTime;
    }

    mapping(address => Info) public _info;

    uint checkinInterval = 5 minutes;// 签到最小有效周期，一天，测试可以调整
    uint public totalCnt; // 总签到数

    function checkin(address to) public {
        require(check(msg.sender));
        Info storage info = _info[to];

        uint d1 = now / checkinInterval;
        uint d2 = info.latestCheckinTime / checkinInterval;
        if (d1 - d2 == 1) {
            totalCnt++;
            info.totalCnt++;
            info.continuousCnt++;
            info.latestCheckinTime = now;
        } else if (d1 - d2 > 1) {
            totalCnt++;
            info.totalCnt++;
            info.continuousCnt = 1;
            info.latestCheckinTime = now;
        }
    }
    
    function getCheckinInfo(address to) public view returns (address,uint256,uint256,uint256){
        return (
             to,
             _info[to].totalCnt,
             _info[to].continuousCnt,
             _info[to].latestCheckinTime
        );
    }
    
    /// Checkin
    event CheckinStart(uint);
    event CheckinPrize(address, uint, uint, uint);
  
    /// CheckinData
    struct CheckinData {
        uint start;             // start time
        uint end;               // end time
        address[] id2user;      // userID - 1 => address
        
        address[] checkinResult;   // rank result, filled by dev after rank end
        uint[] checkinPrize;       // rank prize
        

        mapping (address => uint) user2id;  // address => userID
        mapping (uint => uint) pays;        // userID => dice play sum in this rank
    }
    
    CheckinData[] checkins; // check in data
    
    /// update rankData
    function updateCheckin(address player, uint value) public payable returns (bool) {
        require(check(msg.sender));
        require(checkins.length>0);
        require(_info[player].latestCheckinTime>checkins[checkins.length-1].start);
        
        incUserPay(player, value);

        return true;
    }
    
    function incUserPay(address _addr, uint _amount) internal {
        if (checkins.length == 0) {
            return;
        }
        
        CheckinData storage rank = checkins[checkins.length-1];
        
        uint uid = rank.user2id[_addr];
        if (0 == uid) {
            rank.id2user.push(_addr);
            uid = rank.id2user.length;
            rank.user2id[_addr] = uid;
        }
        rank.pays[uid] = rank.pays[uid].add(_amount);
    }
    /// end
    
    /// start a new checkin reward rank, end current rank
    function checkinStart() public onlyOwner {
        if (checkins.length>0) {
            checkins[checkins.length-1].end = block.timestamp;
        }
        address [] memory a;
        address [] memory b;
        uint [] memory c;
        CheckinData memory rank = CheckinData(now, 0, a, b, c);
        
        checkins.push(rank);
        
        emit CheckinStart(checkins.length);
    }
    
    /// rankID start from 1
    function getCurrentCheckin() public view returns (uint checkinID) {
        return checkins.length;
    }
    
    /// rankID start from 1
    /// start from 1
    function getCheckinData(uint checkinID, uint start, uint end) public view returns (uint, address[] memory, uint[] memory) {
        if (checkinID > checkins.length || 0 == checkinID) {
            return;
        }
        
        CheckinData storage rank = checkins[checkinID-1];
        
        uint len = rank.id2user.length; // max user id
        if (0 == len) {
            return;
        }
        
        require(start >=1 && start <= end && end.sub(start) <= 100);
        
        if (end >= len) {
            end = len;
            if (start > end) {
                start = end;
            }
        }
        
        address[] memory addrs = new address[](end - start+1);
        uint[] memory pays = new uint[](end - start+1);
        
        uint idx = 0;
        for (uint i = start; i <= end; i++) {
            addrs[idx] = rank.id2user[i-1];
            pays[idx] = rank.pays[i];
            idx++;
        }
        
        return (len, addrs, pays);
    }
  
    /// store check result
    function setCheckinResult(uint checkinID, address[] bonusResult, uint [] rewards ) public onlyOwner {
        require(checkinID < checkins.length && checkinID > 0);
        require(bonusResult.length == rewards.length);

        CheckinData storage rank = checkins[checkinID-1];
        require(0 == rank.checkinResult.length);
        
        for (uint i = 0; i < bonusResult.length; i++) {
            if (address(0) != bonusResult[i]) {
                uint prize = rewards[i] ;
                rank.checkinPrize.push(prize);
                rank.checkinResult.push(bonusResult[i]);
                bonusResult[i].transfer(prize);
                emit CheckinPrize(bonusResult[i], i+1, prize, checkinID-1);
            }
        }
    }
    
    /// read rank result
    function getCheckinResult(uint checkinID) public view returns(address[] memory) {
        if (checkinID > checkins.length || 0 == checkinID) {
            return;
        }
        
        CheckinData storage rank = checkins[checkinID-1];
        if (rank.checkinResult.length == 0) {
            return;
        }
        
        address[] memory checkinResult = new address[](rank.checkinResult.length);
        for (uint i = 0; i < rank.checkinResult.length; i++) {
            checkinResult[i] = rank.checkinResult[i];
        }
        
        return checkinResult;
    }

    /// end Ranking
}
