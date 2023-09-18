// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Receivers & Bidders mocks
contract ReceiverGoodMock {
    receive() external payable {}
    fallback()  external payable {}
}

contract ReceiverNoFallbackMock {
    bool public dummy = true;
}

contract ReceiverRevertMock {
    receive() external payable {
        revert();
    }
    fallback()  external payable {
        revert();
    }
}

contract ReceiverHighGasMock {
    bool public paid;
    event Payment(address from, uint256 amount);
    receive() external payable {
        paid = true;
        emit Payment(msg.sender, msg.value);
    }
    fallback()  external payable {
        paid = true;
        emit Payment(msg.sender, msg.value);
    }
}

interface ISafePaymentMock {
    function sendETH(address to) external payable returns (bool);
}

contract ReceiverReentrantMock {
    address private immutable target;
    constructor(address _target) {
        target = _target;
    }
    receive() external payable {
        ISafePaymentMock(msg.sender).sendETH{value: msg.value}(target);
    }
}

interface INFTAuction {
    function bid(uint256 tokenId) external payable;
}

contract MaliciousBidderMock {
    receive() external payable {
        revert();
    }

    function bid(address auction, uint256 tokenId) external payable {
        INFTAuction(auction).bid{value: msg.value}(tokenId);
    }
}
