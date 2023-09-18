pragma solidity ^0.4.25;
contract EthBay {
   struct auction {
      uint highestBid;
      address highestBidder;
      address recipient;
      string name;
   }
   mapping(uint => auction) Auctions;
   uint public totalAuctions;
  event Update(string name, uint highestBid, address highestBidder, address recipient, uint auctionID);
  event Ended(uint auctionID);
  function startAuction(string name, uint timeLimit) public returns (uint auctionID) {
     auctionID = totalAuctions++;
     Auctions[auctionID].recipient = msg.sender;
     Auctions[auctionID].name = name;
    emit Update(name, Auctions[auctionID].highestBid, Auctions[auctionID].highestBidder, Auctions[auctionID].recipient, auctionID);
   }
   function placeBid(uint id) public payable returns (address highestBidder) {
      auction storage  a = Auctions[id];
      if (a.highestBid + 1*10^18 > msg.value) {
         msg.sender.transfer(msg.value);
         return a.highestBidder;
      }
      a.highestBidder.transfer(a.highestBid);
      a.highestBidder = msg.sender;
      a.highestBid = msg.value;
      emit Update(a.name, a.highestBid, a.highestBidder, a.recipient, id);
      return msg.sender;
   }
   function endAuction(uint id) public payable returns (address highestBidder) {
      auction storage a = Auctions[id];
      if (msg.sender != a.recipient) {
         msg.sender.transfer(msg.value);
         return a.recipient;
      }
      a.recipient.transfer(a.highestBid);
      a.highestBid = 0;
      a.highestBidder =address(0);
      a.recipient = address(0);
      emit Ended(id);
   }
   function getHighestBid(uint id) public view returns (uint highestBid) {
      return Auctions[id].highestBid;
   }

   function getAuction(uint id) public view returns (uint , address , address , string memory) {
      auction storage a = Auctions[id];
      return(a.highestBid,a.highestBidder,a.recipient,a.name);
   }
}
