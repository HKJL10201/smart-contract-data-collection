pragma solidity ^0.4.15;

import './XREDTokenSaleMock.sol';

// @dev XREDTokenSaleTokenMock for ERC20 tests purpose.
// As it also deploys MiniMeTokenFactory, nonce will increase and therefore will be broken for future deployments

contract XREDTokenSaleTokenMock is XREDTokenSaleMock {
  function XREDTokenSaleTokenMock(address initialAccount, uint initialBalance)
    XREDTokenSaleMock(10, 20, msg.sender, msg.sender, 100, 50, 2)
    {
      XREDCoin token = new XREDCoin(new MiniMeTokenFactory());
      XREDCoinPlaceholder networkPlaceholder = new XREDCoinPlaceholder(this, token);
      token.changeController(address(this));

      setXREDCoin(token, networkPlaceholder, new SaleWallet(msg.sender, 20, address(this)));
      allocatePresaleTokens(initialAccount, initialBalance, uint64(now), uint64(now));
      activateSale();
      setMockedBlockNumber(21);
      finalizeSale(mock_hiddenCap, mock_capSecret);

      token.changeVestingWhitelister(msg.sender);
  }
}
