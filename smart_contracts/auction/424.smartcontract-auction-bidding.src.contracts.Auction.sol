pragma solidity ^0.8.10;

contract Auction {
    // props
    address private owner;
    uint256 public startTime;
    uint256 public endTime;
    mapping(address => uint256) public bids;
    address[] public addressBids;

    struct Car {
        string make;
        string model;
        string year;
        string colour;
    }

    struct HighestBid {
        uint256 bidAmount;
        address bidder;
    }

    Car public currentCar;
    HighestBid public highestBid;

    modifier isOngoing() {
        require(block.timestamp < endTime, 'This auction is closed.');
        _;
    }
    modifier notOngoing() {
        require(block.timestamp >= endTime, 'This auction is still open');
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner, 'Only owner can perform task.');
        _;
    }
    modifier notOwner() {
        require(msg.sender != owner, 'Owner is not allowed to bid');
        _;
    }

    // events
    event LogBid(address indexed _highestBidder, uint256 _highestBid);
    event LogWithdrawal(address indexed _withdrawer, uint256 amount);

    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp + 1 hours;

        currentCar.make = 'Acura';
        currentCar.model = 'CSX';
        currentCar.year = '2008';
        currentCar.colour = 'Black';
    }

    function makeBid() public payable isOngoing() notOwner() returns (bool) {
        uint256 bidAmount = bids[msg.sender] + msg.value;
        require(bidAmount > highestBid.bidAmount, 'Bid error: Make a higher Bid.');

        highestBid.bidder = msg.sender;
        highestBid.bidAmount = bidAmount;
        bids[msg.sender] = bidAmount;
        emit LogBid(msg.sender, bidAmount);
        return true;
    }

    function withdraw() public notOngoing() isOwner() returns (bool) {
        uint256 amount = highestBid.bidAmount;
        bids[highestBid.bidder] = 0;
        highestBid.bidder = address(0);
        highestBid.bidAmount = 0;

        (bool success, ) = payable(owner).call{ value: amount }("");
        require(success, 'Withdrawal failed.');
        emit LogWithdrawal(msg.sender, amount);
        return true;
    }

    function fetchEndTime() public view returns(uint256) {
        return endTime;
    }


    function fetchTimeDifference() public view returns(uint) {
        uint diff = (endTime - startTime);
        return diff;
    }

    function fetchHighestBid() public view returns (HighestBid memory) {
        HighestBid memory _highestBid = highestBid;
        return _highestBid;
    }

    function fetchCurrentCarDetails() public view returns (Car memory) {
        Car memory _car = currentCar;
        return _car;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBidCount() private view returns (uint) {
        return addressBids.length;
    }
}