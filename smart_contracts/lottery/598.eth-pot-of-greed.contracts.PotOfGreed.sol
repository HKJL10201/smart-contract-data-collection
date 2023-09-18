pragma solidity ^0.5.0;

contract Utility {
  address payable owner;

  event errorEvent(string err);

  modifier onlyOwner {
    if (msg.sender != owner) {
      emit errorEvent("Access denied. Do no have owner permissions.");
    } else {
      _;
    }
  }
}

contract PotOfGreed is Utility {
  constructor () public {
    // creator of contract
    owner = msg.sender;
  }

  uint256 public pot = 0;
  uint public constant minimumInput = 1;
  uint public lastGreed;

  
  function greed() public payable {
      require(msg.value > minimumInput, "Not enough money sent. Need > 1 wei");
      lastGreed = msg.value;
      updatePot(msg.value);
      roll();
  }
  
  function updatePot(uint value) internal {
    pot = pot + value;
  }
  
  function roll () internal {
      if (msg.sender == owner) {
          payout();
      }
  }
  
  function payout() internal {
      uint256 payoutAmt = (pot * 9 / 10);
      pot = pot - payoutAmt;
      msg.sender.transfer(payoutAmt);
  }
  
  function destroy () onlyOwner public {
      selfdestruct(owner);
  }
}
