// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // Lottery states
    enum LOTTERY_STATE {
        CLOSED,
        OPENED,
        PROCESSING
    }
    LOTTERY_STATE public lotteryState;
    uint256 public randomness;
    uint256 public entryCounter;
    uint256 public entryFee;
    uint256 public fee; 
    uint256 public lotteryDuration;
    uint256 public lotteryDeadlineTimestamp;    
    bytes32 public keyhash;
    address public latestWinner;
    mapping(address => uint256) public participantEntries;
    mapping(uint256=>address) public entryIdToParticipant;
    AggregatorV3Interface public priceFeed;

    // events
    event LotteryStarted(uint256 timeStamp);
    event LotteryFinished(address winner, uint256 timeStamp);
    event NewEntry(address participant, uint256 entryId);
    event UserPaid(address user, uint256 amount);
    event RequestedRandomness(bytes32 requestId);

    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _linkTokenAddress,
        uint256 _entryFee,
        uint256 _fee,
        bytes32 _keyhash
    ) VRFConsumerBase(_vrfCoordinator, _linkTokenAddress) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        // amount players must pay in order to enter the lottery
        entryFee = _entryFee;
        fee = _fee;
        keyhash = _keyhash;
        lotteryState = LOTTERY_STATE.CLOSED;
        // 24 hours
        lotteryDuration = 86400;
    }
    // modifiers
    modifier onlyOpened {
        require(lotteryState == LOTTERY_STATE.OPENED, "Lottery must be opened");
        _;
    }

    modifier onlyClosed {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery must be closed");
        _;
    }

    modifier notZero(uint256 _number) {
        require(_number != 0, "This parameter cannot be zero");
        _;
    }

    function getEntryFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 ethPrice = uint256(price) * 10**10;
        uint256 precision = 10**18;
        return (entryFee * precision) / ethPrice;
    }

    function enterLottery(uint256 _numberOfEntries) 
        public 
        payable 
        onlyOpened 
        notZero(_numberOfEntries)
    {
        uint256 _fee = getEntryFee();
        require(msg.sender != address(0), "invalid user address");
        require(msg.value >= _fee * _numberOfEntries, "You need to spend more ETH!");
        require(
            block.timestamp < lotteryDeadlineTimestamp, 
            "The lottery deadline is finished"
        );
        // In case of the user send an amount greater than the necessary, refund the user
        uint256 amountToBeRefund = msg.value - (_fee * _numberOfEntries);
        if (amountToBeRefund > 0) {
            payUser(msg.sender, amountToBeRefund);
        }
        
        for (uint256 counter = 0; counter < _numberOfEntries; counter++) {
            entryIdToParticipant[entryCounter] = msg.sender;
            participantEntries[msg.sender]++;
            entryCounter++;
            emit NewEntry(msg.sender, entryCounter - 1);    
        }
    }

    function payUser(address _user, uint256 _amount) internal notZero(_amount) {
        require(_user != address(0), "invalid user address");
        payable(_user).transfer(_amount);
        emit UserPaid(_user, _amount);
    }

    function startLottery() public onlyClosed {
        lotteryState = LOTTERY_STATE.OPENED;
        lotteryDeadlineTimestamp = block.timestamp + lotteryDuration;
        emit LotteryStarted(block.timestamp);
    }

    function endLottery() public onlyOpened {
        require(
            block.timestamp >= lotteryDeadlineTimestamp,
            "The lottery is not finished yet"
        );
        lotteryState = LOTTERY_STATE.PROCESSING;
        bytes32 requestId = requestRandomness(keyhash, fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
        notZero(_randomness)
    {
        require(
            lotteryState == LOTTERY_STATE.PROCESSING,
            "The contract is not processing the winner yet"
        );
        uint256 entryIdOfWinner = _randomness % entryCounter;
        latestWinner = entryIdToParticipant[entryIdOfWinner];
        // The winner recieves 90% of the contract balance
        // The other 10% goes to the owner
        uint256 contractBalance = address(this).balance;
        uint256 amountToPayWinner = (contractBalance * 90) / 100;
        uint256 amountToPayOwner = (contractBalance * 10) / 100;
        payUser(latestWinner, amountToPayWinner);
        payUser(owner(), amountToPayOwner);
        // Reset 
        lotteryState = LOTTERY_STATE.CLOSED;
        for (uint index = 0; index < entryCounter; index++) {
            participantEntries[entryIdToParticipant[index]] = 0;
        }
        entryCounter = 0;
        randomness = _randomness;
        emit LotteryFinished(latestWinner, block.timestamp);
    }

    function changeEntryFee(uint256 _newEntryFee)
        public
        onlyOwner
        onlyClosed
        notZero(_newEntryFee)
    {
        entryFee = _newEntryFee;
    }

    function changeDuration(uint256 _newDuration) 
        public
        onlyOwner 
        onlyClosed
        notZero(_newDuration)
    {
        lotteryDuration = _newDuration;
    }
}
