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

contract Checkin is Ownable {

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

    uint checkinInterval = 1 days;// 签到最小有效周期，一天，测试可以调整
    uint public totalCnt; // 总签到数

    function checkin() public {
       // require(check(msg.sender));
        Info storage info = _info[msg.sender];

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

}
