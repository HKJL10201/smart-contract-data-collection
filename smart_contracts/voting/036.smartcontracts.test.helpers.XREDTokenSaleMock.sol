pragma solidity ^0.4.15;

import '../../contracts/XREDTokenSale.sol';

// @dev XREDTokenSaleMock mocks current block number

contract XREDTokenSaleMock is XREDTokenSale {
  uint mock_blockNumber = 1;
  uint public mock_hiddenCap = 100 finney;
  uint public mock_capSecret = 1;

  function XREDTokenSaleMock (
      uint _initialBlock,
      uint _finalBlock,
      address _XREDDevMultisig,
      address _communityMultisig,
      uint256 _initialPrice,
      uint256 _finalPrice,
      uint8 _priceStages
  ) XREDTokenSale(_initialBlock, _finalBlock, _XREDDevMultisig, _communityMultisig, _initialPrice, _finalPrice, _priceStages, computeCap(mock_hiddenCap, mock_capSecret)) {}

  function getBlockNumber() internal constant returns (uint) {
    return mock_blockNumber;
  }

  function setMockedBlockNumber(uint _b) {
    mock_blockNumber = _b;
  }

  function setMockedTotalCollected(uint _totalCollected) {
    totalCollected = _totalCollected;
  }
}
