pragma solidity ^0.4.15;

import "truffle/Assert.sol";
import "zeppelin/contracts/token/ERC20.sol";
import "./helpers/XREDTokenSaleMock.sol";
import "./helpers/ThrowProxy.sol";
import "./helpers/MultisigMock.sol";

contract TestTokenPresale {
  uint public initialBalance = 200 finney;

  XREDCoin token;

  ThrowProxy throwProxy;

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function deployAndSetXREDCoin(XREDTokenSale sale) {
    XREDCoin a = new XREDCoin(new MiniMeTokenFactory());
    a.changeController(sale);
    a.setCanCreateGrants(sale, true);
    sale.setXREDCoin(a, new XREDCoinPlaceholder(address(sale), a), new SaleWallet(sale.XREDDevMultisig(), sale.finalBlock(), address(sale)));
  }

  function testCreateSale() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, 0x1, 0x2, 3, 1, 2);

    Assert.isFalse(sale.isActivated(), "Sale should be activated");
    Assert.equal(sale.totalCollected(), 0, "Should start with 0 funds collected");
  }

  function testCantInitiateIncorrectSale() {
    TestTokenPresale(throwProxy).throwIfStartPastBlocktime();
    throwProxy.assertThrows("Should throw when starting a sale in a past block");
  }

  function throwIfStartPastBlocktime() {
    new XREDTokenSaleMock(0, 20, 0x1, 0x2, 3, 1, 2);
  }

  function testActivateSale() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetXREDCoin(sale);
    sale.activateSale();
    Assert.isTrue(sale.isActivated(), "Should be activated");
  }

  function testCannotActivateBeforeDeployingXREDCoin() {
    TestTokenPresale(throwProxy).throwsWhenActivatingBeforeDeployingXREDCoin();
    throwProxy.assertThrows("Should have thrown when activating before deploying XREDCoin");
  }

  function throwsWhenActivatingBeforeDeployingXREDCoin() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    sale.activateSale();
  }

  function testCannotRedeployXREDCoin() {
    TestTokenPresale(throwProxy).throwsWhenRedeployingXREDCoin();
    throwProxy.assertThrows("Should have thrown when redeploying XREDCoin");
  }

  function throwsWhenRedeployingXREDCoin() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetXREDCoin(sale);
    deployAndSetXREDCoin(sale);
  }

  function testOnlyMultisigCanDeployXREDCoin() {
    TestTokenPresale(throwProxy).throwsWhenNonMultisigDeploysXREDCoin();
    throwProxy.assertThrows("Should have thrown when deploying XREDCoin from not multisig");
  }

  function throwsWhenNonMultisigDeploysXREDCoin() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, 0x1, 0x3, 3, 1, 2);
    deployAndSetXREDCoin(sale);
  }

  function testThrowsIfPlaceholderIsBad() {
    TestTokenPresale(throwProxy).throwsWhenNetworkPlaceholderIsBad();
    throwProxy.assertThrows("Should have thrown when placeholder is not correct");
  }

  function throwsWhenNetworkPlaceholderIsBad() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    XREDCoin a = new XREDCoin(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setXREDCoin(a, new XREDCoinPlaceholder(address(sale), address(sale)), new SaleWallet(sale.XREDDevMultisig(), sale.finalBlock(), address(sale))); // should be initialized with token address
  }

  function testThrowsIfSaleIsNotTokenController() {
    TestTokenPresale(throwProxy).throwsWhenSaleIsNotTokenController();
    throwProxy.assertThrows("Should have thrown when sale is not token controller");
  }

  function throwsWhenSaleIsNotTokenController() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    XREDCoin a = new XREDCoin(new MiniMeTokenFactory());
    // Not called a.changeController(sale);
    sale.setXREDCoin(a, new XREDCoinPlaceholder(address(sale), a), new SaleWallet(sale.XREDDevMultisig(), sale.finalBlock(), address(sale))); // should be initialized with token address
  }

  function testThrowsSaleWalletIncorrectBlock() {
    TestTokenPresale(throwProxy).throwsSaleWalletIncorrectBlock();
    throwProxy.assertThrows("Should have thrown sale wallet releases in incorrect block");
  }

  function throwsSaleWalletIncorrectBlock() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    XREDCoin a = new XREDCoin(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setXREDCoin(a, new XREDCoinPlaceholder(address(sale), a), new SaleWallet(sale.XREDDevMultisig(), sale.finalBlock() - 1, address(sale)));
  }

  function testThrowsSaleWalletIncorrectMultisig() {
    TestTokenPresale(throwProxy).throwsSaleWalletIncorrectMultisig();
    throwProxy.assertThrows("Should have thrown when sale wallet has incorrect multisig");
  }

  function throwsSaleWalletIncorrectMultisig() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    XREDCoin a = new XREDCoin(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setXREDCoin(a, new XREDCoinPlaceholder(address(sale), a), new SaleWallet(0x1a77ed, sale.finalBlock(), address(sale)));
  }

  function testThrowsSaleWalletIncorrectSaleAddress() {
    TestTokenPresale(throwProxy).throwsSaleWalletIncorrectSaleAddress();
    throwProxy.assertThrows("Should have thrown when sale wallet has incorrect sale address");
  }

  function throwsSaleWalletIncorrectSaleAddress() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    XREDCoin a = new XREDCoin(new MiniMeTokenFactory());
    a.changeController(sale);
    sale.setXREDCoin(a, new XREDCoinPlaceholder(address(sale), a), new SaleWallet(sale.XREDDevMultisig(), sale.finalBlock(), 0xdead));
  }

  function testSetPresaleTokens() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), 0x2, 3, 1, 2);
    deployAndSetXREDCoin(sale);
    sale.allocatePresaleTokens(0x1, 100 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(0x2, 30 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(0x2, 6 finney, uint64(now + 8 weeks), uint64(now + 24 weeks));
    sale.allocatePresaleTokens(address(this), 20 finney, uint64(now + 12 weeks), uint64(now + 24 weeks));
    Assert.equal(ERC20(sale.token()).balanceOf(0x1), 100 finney, 'Should have correct balance after allocation');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now)), 0, 'Should have 0 tokens transferable now');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now + 12 weeks - 1)), 0, 'Should have 0 tokens transferable just before cliff');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now + 12 weeks)), 50 finney, 'Should have some tokens transferable after cliff');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now + 18 weeks)), 75 finney, 'Should have some tokens transferable during vesting');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now + 21 weeks)), 87500 szabo, 'Should have some tokens transferable during vesting');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now + 24 weeks)), 100 finney, 'Should have all tokens transferable after vesting');

    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x2, uint64(now)), 0, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x2, uint64(now + 8 weeks)), 2 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x2, uint64(now + 12 weeks)), 18 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x2, uint64(now + 24 weeks)), 36 finney, 'Should have all tokens transferable after vesting');
    Assert.equal(MiniMeIrrVesDivToken(sale.token()).transferableTokens(0x1, uint64(now + 24 weeks)), 100 finney, 'Should have all tokens transferable after vesting');

    Assert.equal(ERC20(sale.token()).totalSupply(), 156 finney, 'Should have correct supply after allocation');

    Assert.equal(ERC20(sale.token()).balanceOf(this), 20 finney, 'Should have correct balance');
    TestTokenPresale(throwProxy).throwsWhenTransferingPresaleTokensBeforeCliff(sale.token());
    throwProxy.assertThrows("Should have thrown when transfering presale tokens");
  }

  function throwsWhenTransferingPresaleTokensBeforeCliff(address token) {
    ERC20(token).transfer(0xdead, 1);
  }

  function testCannotSetPresaleTokensAfterActivation() {
    TestTokenPresale(throwProxy).throwIfSetPresaleTokensAfterActivation();
    throwProxy.assertThrows("Should have thrown when setting tokens after activation");
  }

  function throwIfSetPresaleTokensAfterActivation() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetXREDCoin(sale);
    sale.activateSale(); // this is both multisigs
    sale.allocatePresaleTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }

  function testCannotSetPresaleTokensAfterSaleStarts() {
    TestTokenPresale(throwProxy).throwIfSetPresaleTokensAfterSaleStarts();
    throwProxy.assertThrows("Should have thrown when setting tokens after sale started");
  }

  function throwIfSetPresaleTokensAfterSaleStarts() {
    XREDTokenSaleMock sale = new XREDTokenSaleMock(10, 20, address(this), address(this), 3, 1, 2);
    deployAndSetXREDCoin(sale);
    sale.setMockedBlockNumber(13);
    sale.allocatePresaleTokens(0x1, 100, uint64(now + 12 weeks), uint64(now + 24 weeks));
  }
}
