// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../ExecutionPrice.sol";

contract TestExecutionPrice is ExecutionPrice {
    uint256 public totalFilledAmount;

    constructor(address _TGEN, address _bondToken, address _marketplace, address _xTGEN)
        ExecutionPrice(_TGEN, _bondToken, _marketplace, _xTGEN)
    {
    }

    function setStartIndex(uint256 _index) external {
        startIndex = _index;
    }

    function setEndIndex(uint256 _index) external {
        endIndex = _index;
    }

    function setIsBuyQueue(bool _isBuyQueue) external {
        isBuyQueue = _isBuyQueue;
    }

    function setNumberOfTokensAvailable(uint256 _amount) external {
        numberOfTokensAvailable = _amount;
    }

    function setOrderIndex(address _user, uint256 _index) external {
        orderIndex[_user] = _index;
    }

    function setOrder(uint256 _index, address _user, uint256 _quantity, uint256 _amountFilled) external {
        orderBook[_index] = Order({
            user: _user,
            quantity: _quantity,
            amountFilled: _amountFilled
        });
    }

    function setIsInitialized(bool _isInitialized) external {
        initialized = _isInitialized;
    }

    function setOwner(address _owner) external {
        params.owner = _owner;
    }

    function setPrice(uint256 _price) external {
        params.price = _price;
    }

    function append(address _user, uint256 _amount) external {
        _append(_user, _amount);
    }

    function executeOrder(uint256 _amount) external {
        totalFilledAmount = _executeOrder(_amount);
    }

    function setFactory(address _factory) external {
        factory = _factory;
    }
}