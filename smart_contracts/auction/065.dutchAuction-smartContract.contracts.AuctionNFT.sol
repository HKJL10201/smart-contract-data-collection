// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC721 {
    function transfer(
        address _from,
        address _to,
        uint256 _nftId
    ) external;
}

contract AuctionNFT {
    address payable public owner;
    address public buyer;
    uint256 public startPrice;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public currentTime;

    IERC721 public immutable nft;
    uint256 public immutable nftId;

    //we auction 1 token per auction by default
    event Bid(address buyer, uint256 amount);
    event GetPrice(uint256 price);
    event CurPrice(uint256 price);

    constructor(
        uint256 startPrice_,
        uint256 startDate_,
        uint256 endDate_,
        address nftAddr_,
        uint256 nftId_
    ) payable {
        require(startPrice_ > 0, "invalid startPrice_");
        require(endDate_ > startDate_, "invalid endDate_ or startDate_");
        owner = payable(msg.sender);
        startPrice = startPrice_;
        startDate = startDate_;
        endDate = endDate_;
        currentTime = block.timestamp;
        nft = IERC721(nftAddr_);
        nftId = nftId_;
    }

    function bid() external payable {
        require(msg.sender != owner, "owner are unable to bid in the Auction");
        require(block.timestamp > startDate, "Auction hasn't started yet");
        require(block.timestamp < endDate, "Auction is Done");
        require(buyer == address(0), "Auction item has been bought");
        require(msg.value < 1e35);

        uint256 price = currentPrice();

        require(msg.value >= price, "amount is lower than price");

        buyer = msg.sender;
        // (bool sent, ) = owner.call{value: msg.value}("");
        // require(sent, "fail to send ETH payment to owner");
        owner.transfer(msg.value);

        nft.transfer(owner, buyer, nftId);

        emit Bid(buyer, msg.value);
    }

    function currentPrice() public payable returns (uint256) {
        require(block.timestamp > startDate, "Auction hasn't started yet");
        uint256 elapse = block.timestamp - startDate;
        uint256 calculated = (elapse * 100) / (endDate - startDate);
        uint256 deduction = (calculated * startPrice) / 100;
        uint256 currPrice = startPrice - deduction;
        return currPrice;
    }
}
