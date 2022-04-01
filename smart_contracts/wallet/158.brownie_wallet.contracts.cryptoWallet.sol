// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract wallet {
    mapping(address => uint256) public fundMapping;
    address owner;
    address[] individuals;
    AggregatorV3Interface public price_feed;

    constructor(address _price_feed) {
        price_feed = AggregatorV3Interface(_price_feed);
        owner = msg.sender;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = get_price();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
    }

    function add_funds() public payable {
        uint256 converted = get_conversionRate(msg.value);
        require(
            converted >= 50 * 10**18,
            "Fund does not meet the minimum amount required!"
        );
        fundMapping[msg.sender] += msg.value;
        individuals.push(msg.sender);
    }

    function get_balance() public view returns (uint256) {
        return address(this).balance;
    }

    modifier Owner() {
        require(
            msg.sender == owner,
            "You don't have permission to withdraw amounts!"
        );
        _;
    }

    function withdraw_amount() public payable Owner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 person = 0; person < individuals.length; person++) {
            fundMapping[individuals[person]] = 0;
        }
        individuals = new address[](0);
    }

    function get_price() public view returns (uint256) {
        (, int256 roundval, , , ) = price_feed.latestRoundData();
        return uint256(roundval * 10**10);
    }

    function get_conversionRate(uint256 wei_value)
        public
        view
        returns (uint256)
    {
        uint256 current_price = get_price();
        return (wei_value * current_price) / 10**18;
    }
}
