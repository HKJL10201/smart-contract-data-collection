//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface IERC721 {
    function transferFrom(address from, address to, uint nftId) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address highestBidder, uint amount);

    //the NFT that we will sell. It will not change for the duration
    // of the contract. Thats why it is immutable.
    IERC721 public immutable nft; 

    //nft id. It will also not change. That is why it is immutable.
    uint public immutable  nftId;

    address payable public immutable seller;

    // uint32 can store 100 years from now. So it is enough for our purpose.
    // And this var is not immutable because will give a value to it not
    // by clicking a function called "start()". Storing timestamp when the auction
    // ends.
    uint32 public endAt;
    bool public started; //will be set to true when the auction starts
    bool public ended; // will be set to true when the auction ends

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) public bids;

    constructor(address _nft, uint _nftId, uint _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    //function to start the auction. Only the seller should be able to start the auction
    // function should be called only once
    function start() external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");

        started = true;
        endAt = uint32(block.timestamp + 60);
        //above endAt is for 60 seconds.
        //if you want it with 7 days, then you should make it as
        //uint32(block.timestamp + 7 days);

        //now we will transfer the ownership of the nft from seller to contract.
        nft.transferFrom(seller, address(this), nftId);
        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest bid");

        if(highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        
        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "not ended");

        ended = true;
        if(highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);

    }
}