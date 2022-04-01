pragma solidity ^0.4.15;

// @dev Contract to hold sale raised funds during the sale period.
// Prevents attack in which the XRED Multisig sends raised ether
// to the sale contract to mint tokens to itself, and getting the
// funds back immediately.

contract AbstractSale {
  function saleFinalized() constant returns (bool);
}

contract SaleWallet {
  // Public variables
  address public multisig;
  uint public finalBlock;
  AbstractSale public tokenSale;

  // @dev Constructor initializes public variables
  // @param _multisig The address of the multisig that will receive the funds
  // @param _finalBlock Block after which the multisig can request the funds
  function SaleWallet(address _multisig, uint _finalBlock, address _tokenSale) {
    multisig = _multisig;
    finalBlock = _finalBlock;
    tokenSale = AbstractSale(_tokenSale);
  }

  // @dev Withdraw function sends all the funds to the wallet if conditions are correct
  function withdraw() public {
    assert(msg.sender == multisig);       // Only the multisig can request it
    if (block.number > finalBlock &&      // Allow after the final block
        tokenSale.saleFinalized()) {      // Allow when sale is finalized
      return doWithdraw();
    }
  }

  function doWithdraw() internal {
    assert(multisig.send(this.balance));
  }

  // @dev Receive all sent funds without any further logic
  function () public payable {}
}
