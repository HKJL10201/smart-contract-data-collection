// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction {
    uint256 public time;
    address payable public owner;
    mapping(address => uint256) public fundersListAmount;
    address[] public fundersList;
    address payable public highestFunder;
    uint256 public maxAmount = 0;

    constructor() {
        owner = payable(msg.sender);
    }

    function start() public {
        time = uint32(block.timestamp + 20);
    }

    function pay() public payable {
        require(
            msg.value > maxAmount,
            "Amount not greater than current max bid"
        );
        require(block.timestamp < time, "TIME UP!!");
        fundersListAmount[msg.sender] = msg.value;
        fundersList.push(msg.sender);
        maxAmount = msg.value;
        highestFunder = payable(msg.sender);
    }

    function withdraw() public {
        highestFunder.transfer(address(this).balance);
    }

    function HighestBidder() public view returns (address) {
        return highestFunder;
    }
}
