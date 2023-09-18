pragma solidity ^0.8.0;

import "./Timer.sol";

/// This contract represents most simple crowdfunding campaign.
/// This contract does not protect investors from not receiving goods
/// they were promised from crowdfunding owner. This kind of contract
/// might be suitable for campaigns that do not promise anything to the
/// investors except that they will start working on some project.
/// (e.g. almost all blockchain spinoffs.)
contract Crowdfunding {
    address private owner;
    Timer private timer;
    uint256 public goal;
    uint256 public endTimestamp;
    uint256 public totalInvested;
    mapping(address => uint256) public investments;
    bool public isCompleted;

    constructor(
        address _owner,
        Timer _timer,
        uint256 _goal,
        uint256 _endTimestamp
    ) {
        owner = (_owner == address(0) ? msg.sender : _owner);
        timer = _timer;
        // Not checking if this is correctly injected.
        goal = _goal;
        endTimestamp = _endTimestamp;
        totalInvested = 0;
        isCompleted = false;
    }

    function invest() public payable {
        require(!isCompleted);
        require(timer.getTime() <= endTimestamp);
        investments[msg.sender] += msg.value;
        totalInvested += msg.value;
        isCompleted = totalInvested >= goal ? true : false;
    }

    function claimFunds() public {
        require(isCompleted);
        require(time() > endTimestamp);
        require(msg.sender == owner);
        payable(msg.sender).transfer(totalInvested);
    }

    function refund() public {
        require(!isCompleted);
        require(time() > endTimestamp);
        uint256 amountToRefund = investments[msg.sender];
        investments[msg.sender] = 0;
        totalInvested -= amountToRefund;
        payable(msg.sender).transfer(amountToRefund);
    }

}
