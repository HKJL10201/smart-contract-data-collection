  // SPDX-License-Identifier: MIT
  pragma solidity ^0.8.9;

  contract AssetAuction {
      // AssetAuction parameters
      address public immutable purchaser;
      uint public endTime;
      
      // states for our Auction
      uint public largestBid;
      address public largestBidder;
      bool public completed;

      //Tracking our withdrawals
      mapping (address => uint) pendingWithdrawals;

      //Events
      event Bid(address indexed bidder, uint amount);
      event AuctionEnd(address winner, uint amount); 

      constructor (address _purchaser, uint _durationMinutes) {
          purchaser = _purchaser;
          endTime = block.timestamp + _durationMinutes * 1 minutes;
      }

      function bid() public payable {
          require (block.timestamp < endTime, 'Auction has ended');
          require (msg.value > largestBid, 'A higher bid has been placed already');
          if (largestBid != 0){
              pendingWithdrawals[largestBidder] += largestBid;
          }
          largestBid = msg.value;
          largestBidder = msg.sender;
          emit Bid(msg.sender, msg.value);
      }

      function withdraw() external returns (uint amount) {
          amount = pendingWithdrawals[msg.sender];
          if (amount > 0 ) {
              pendingWithdrawals[msg.sender] = 0;
              payable (msg.sender).transfer (amount);
          }
      }

      function auctionEnd() external {
          // 1. Conditions check
          require (!completed, 'Auction has ended');
          require (block.timestamp >= endTime);

          // 2. Apply internal state changes
          completed = true;
          emit AuctionEnd(largestBidder, largestBid);

          // 3. Interact with addresses
          payable(purchaser).transfer(largestBid);
      }
    }