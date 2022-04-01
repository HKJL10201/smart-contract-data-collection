pragma solidity ^0.4.15;

import "./interface/TokenController.sol";
import "./XREDCoin.sol";

/**
  *  Copyright 2017, Konstantin Viktorov (XRED Foundation)
  *  Copyright 2017, Jorge Izquierdo (Aragon Foundation)
  **/

/*

@notice The XREDCoinPlaceholder contract will take control over the XREDCoin after the sale
        is finalized and before the XRED Network is deployed.

        The contract allows for XREDCoin transfers and transferFrom and implements the
        logic for transfering control of the token to the network when the sale
        asks it to do so.
*/

contract XREDCoinPlaceholder is TokenController {
  address public sale;
  XREDCoin public token;

  function XREDCoinPlaceholder(address _sale, address _XREDCoin) {
    sale = _sale;
    token = XREDCoin(_XREDCoin);
  }

  function changeController(address network) public {
    assert(msg.sender == sale);
    token.changeController(network);
    suicide(network);
  }

  // In between the sale and the network. Default settings for allowing token transfers.
  function proxyPayment(address _owner) payable public returns (bool) {
    revert();
    return false;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns (bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns (bool) {
    return true;
  }
}
