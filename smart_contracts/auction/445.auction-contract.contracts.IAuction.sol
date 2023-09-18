// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAuction {
     
      function auctionAction(uint _bidTime, address payable _beneficiary) external;
      function placeBid() external payable;
      function withdraw() external payable returns(bool success);
      function auctionClose() external;
}
