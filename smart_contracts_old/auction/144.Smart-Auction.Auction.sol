// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract Auction {
    address payable private producer;
    address payable private winner;
    uint private depositValue;
    uint private bidEndTime;
    uint private revealEndTime;
    uint private highestBid;
    uint private secondHighestBid;
    bool private paid;
    mapping(address => bytes32) bids;

    constructor(uint _bidDuration, uint _revealDuration) payable {
        producer = msg.sender;
        depositValue = msg.value;
        bidEndTime = block.timestamp + _bidDuration;
        revealEndTime = bidEndTime + _revealDuration;
        highestBid = 0;
        secondHighestBid = 0;
        winner = address(0);
    }

    function bid(bytes32 _bidHash) public payable {
        require(block.timestamp < bidEndTime, "Bidding phase is over");
        require(msg.value == depositValue, "Deposit value should be exact");
        require(bids[msg.sender] == bytes32(0), "User can bid only once");
        bids[msg.sender] = _bidHash;
    }

    function reveal(uint _bidValue, string memory _secret) public {
        require(block.timestamp >= bidEndTime, "Bidding phase is still on");
        require(block.timestamp < revealEndTime, "Reveal phase is over");
        require(bids[msg.sender] != bytes32(0), "Cannot proceed with this user");
        bytes32 bidHash = bids[msg.sender];
        handleBidHash(bidHash, _bidValue, _secret);
    }

    function handleBidHash(bytes32 _bidHash, uint _bidValue, string memory _secret) private {
        if (_bidHash == keccak256(abi.encodePacked(_bidValue, _secret))) {
            adjustBidOrder(_bidValue, msg.sender);
            msg.sender.transfer(depositValue);
        }
        // Avoid double spending by correct revealers
        // Lock deposits of wrong revealers
        bids[msg.sender] = bytes32(0);
    }

    function adjustBidOrder(uint _bid, address payable _bidder) private {
        if (_bid > highestBid) {
            secondHighestBid = highestBid;
            highestBid = _bid;
            winner = _bidder;
        }
        else if (_bid > secondHighestBid) { secondHighestBid = _bid; }
    }

    function pay() public payable {
        require(msg.sender == winner, "Only auction winner can pay");
        require(msg.value >= secondHighestBid + depositValue, "Payment value should be exact");
        require(block.timestamp >= revealEndTime, "Reveal phase is not over yet");
        depositValue = msg.value - secondHighestBid;
        paid = true;
    }

    function confirm() public {
        require(msg.sender == winner, "Only auction winner can confirm payment");
        require(block.timestamp >= revealEndTime, "Reveal phase is not over yet");
        require(paid, "You did not pay yet");
        producer.transfer(secondHighestBid + depositValue);
        winner.transfer(depositValue);
    }

    function abort() public {
        require(msg.sender == winner, "Only auction winner can abort");
        require(paid, "You did not pay yet");
        winner.transfer(secondHighestBid);
        // Deposit is not returned as an incentive not to lie
    }
}