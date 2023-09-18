pragma solidity ^0.4.24;

contract VickreyAuction {
  address seller;
  bool isOpen;
  uint totalBuyers;
  mapping (uint => address) buyers;
  uint[] offers;
  //define the lowest acceptable price
  uint starting;

  modifier open() {
    require(isOpen == true);
    _;
  }
  modifier enough(uint price) {
    require(starting < price);
    _;
  }

  function VickreyAuction(uint _starting) {
    seller = msg.sender;
    isOpen = true;
    totalBuyers = 0;
    starting = _starting;
  }

  function getTotalBuyers() returns (uint) {
    return totalBuyers;
  }

  function getIsOpen() returns (bool) {
    return isOpen;
  }

  function bid(uint price, address buyer) open enough(price) {
    buyers[totalBuyers] = buyer;
    offers.push(price);
    totalBuyers++;
  }

  function closeAuction() {
    isOpen = false;
  }

  function findWinner() returns (address, uint) {
    uint highestPrice = 0;
    uint higherPrice = 0;
    address winner;
    for(uint i = 0; i < offers.length; i++){
      if(highestPrice < offers[i]){
        higherPrice = highestPrice;
        highestPrice = offers[i];
        winner = buyers[i];
      }else{
        if(higherPrice < offers[i]){
          higherPrice = offers[i];
        }
      }
    }
    return (winner, higherPrice);
  }

  function trade() payable{
    if (!seller.send(msg.value)) revert();
  }

  /*function getBalance(address addr) returns(uint) {
        return balances[addr];
    }*/
}
