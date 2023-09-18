pragma solidity ^0.5.0;

contract BidderDto {
    struct Bidder {
        uint token_id;
        address bidderWallet;
        uint bidAmount;
    }
    
    
    Bidder[] bidderList;
    
    mapping(address => Bidder) bidMap;
    
   // mapping(address => BidHelperToken) bidHelperMap;
    
    Bidder bidders;
    
    
/*    constructor(address payable _bidderWallet, string memory _bidderName, uint _bidAmount) public {
        bidders = Bidder(_bidderWallet,_bidderName,_bidAmount);
    }*/

  function add(uint token_id,address _bidderWallet, uint _bidAmount) public {
      bidders = Bidder(token_id,_bidderWallet,_bidAmount);
      bidderList.push(bidders);
      bidMap[_bidderWallet] = bidders;
  }


   function getBidderAddress() public view returns (address) {
      return bidders.bidderWallet;
   }
   
    function setBidderAddress(address payable _bidderWallet) public {
      bidders.bidderWallet = _bidderWallet;
   }
   
/*   
   function getBidderName() public view returns (string memory) {
      return bidders.bidderName;
   }
   
      function setBidderName(string memory _bidderName) public { 
          bidders.bidderName = _bidderName;
   }*/
   
   
      function getBidderAmount() public view returns (uint) {
      return bidders.bidAmount;
   }
   
      function setBidderAmount(uint _bidAmount) public { 
          bidders.bidAmount = _bidAmount;
   }
   
   
}