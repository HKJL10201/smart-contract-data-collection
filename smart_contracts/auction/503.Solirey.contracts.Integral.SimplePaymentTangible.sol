// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ParentSimplePayment.sol";

contract SimplePaymentTangible is ParentSimplePayment {
    constructor(address solireyAddress) ParentSimplePayment(solireyAddress) {
        solirey = Solirey(solireyAddress);
    }

    function createPayment(uint price) external {
        require(price > 0, "Wrong price");

        solirey.incrementUid();
        uint256 uid = solirey.currentUid();

        emit CreatePayment(uid);
        
        solirey.incrementToken();

        uint256 newTokenId = solirey.currentToken();
        solirey.mint(address(this), newTokenId);

        _simplePayment[uid].price = price;
        _simplePayment[uid].tokenId = newTokenId;
        _simplePayment[uid].seller = msg.sender;
    }

    // id is the posting identifier
    function pay(uint id) external payable {
        Payment memory sp = _simplePayment[id];

        require(  
            sp.price > 0,
            "Not for sale"
        );

        require(
            msg.value == sp.price,
            "Incorrect price"
        );   
        
        // make a payment for the seller to withdraw
        uint _fee = msg.value * 2 / 100;
       sp.payment = msg.value - _fee;
       sp.fee = _fee;
        
        // transfer the token
        uint256 tokenId = sp.tokenId;
        solirey.transferFrom(address(this), msg.sender, tokenId);
        sp.price = 0; // not for sale anymore
        
        _simplePayment[id] = sp;

        emit PaymentMade(id);
    }
    
    function withdraw(uint id) external {
        Payment memory sp = _simplePayment[id];

        require(msg.sender == sp.seller, "Not authorized");
        require(sp.payment != 0, "Already withdrawn");

        _simplePayment[id].payment = 0;
        
        payable(msg.sender).transfer(sp.payment);
    }
}