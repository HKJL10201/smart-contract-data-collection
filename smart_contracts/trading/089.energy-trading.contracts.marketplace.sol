pragma solidity >=0.7.0 <0.9.0;

import "./registeruser.sol"
import "hardhat/console.sol"

contract EnergyMarketplace is registerUser {
  struct Ask {
    address producer;
    uint32 energy; // in kWh
    uint32 price;
    uint64 timestamp; // asks expire within 24 hours
  }

  struct Bid {
    address buyer;
    uint32 energy; // in kWh
    uint32 price;
    uint64 timestamp;
  }

  Ask[] asks;
  Bid[] bids;

  function submitOffer(uint32 _energy, uint32 _price) isRegistered {
    require(energy >= 1);

    asks.push(Ask({
      producer: msg.sender,
      energy: _energy,
      price: _price,
      timestamp: now
      }));
  }

  function submitBid(uint32 _energy, uint32 _price) isRegistered {
    require(energy >= 1);

    bids.push(Bid({
      buyer: msg.sender,
      energy: _energy,
      price: _price,
      timestamp: now
      }));
  }
}