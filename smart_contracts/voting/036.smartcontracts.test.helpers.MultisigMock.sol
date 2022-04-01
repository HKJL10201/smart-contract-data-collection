pragma solidity ^0.4.15;

import "./XREDTokenSaleMock.sol";

contract MultisigMock {
  function deployAndSetXREDCoin(address sale) {
    XREDCoin token = new XREDCoin(new MiniMeTokenFactory());
    XREDCoinPlaceholder networkPlaceholder = new XREDCoinPlaceholder(sale, token);
    token.changeController(address(sale));

    XREDTokenSale s = XREDTokenSale(sale);
    token.setCanCreateGrants(sale, true);
    s.setXREDCoin(token, networkPlaceholder, new SaleWallet(s.XREDDevMultisig(), s.finalBlock(), sale));
  }

  function activateSale(address sale) {
    XREDTokenSale(sale).activateSale();
  }

  function emergencyStopSale(address sale) {
    XREDTokenSale(sale).emergencyStopSale();
  }

  function restartSale(address sale) {
    XREDTokenSale(sale).restartSale();
  }

  function finalizeSale(address sale) {
    finalizeSale(sale, XREDTokenSaleMock(sale).mock_hiddenCap());
  }

  function withdrawWallet(address sale) {
    SaleWallet(XREDTokenSale(sale).saleWallet()).withdraw();
  }

  function finalizeSale(address sale, uint256 cap) {
    XREDTokenSale(sale).finalizeSale(cap, XREDTokenSaleMock(sale).mock_capSecret());
  }

  function deployNetwork(address sale, address network) {
    XREDTokenSale(sale).deployNetwork(network);
  }

  function () payable {}
}
