// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();

/** @title A contract for crowdfunding
 *  @author Vedant Patil
 *  @notice This is a demo contract for funding
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToFunds;

    AggregatorV3Interface private s_priceFeed;

    constructor(address _priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MIN_USD,
            "Didn't send enough ETH"
        );
        if (s_addressToFunds[msg.sender] == 0) s_funders.push(msg.sender);
        s_addressToFunds[msg.sender] = s_addressToFunds[msg.sender] + msg.value;
    }

    function withdraw() public onlyOwner {
        // creating memory address as it is lot more gas efficient than storage
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            s_addressToFunds[funders[i]] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to withdraw funds");
    }

    // View / pure functions
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 idx) public view returns (address) {
        return s_funders[idx];
    }

    function getAddressToFund(address funder) public view returns (uint256) {
        return s_addressToFunds[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
