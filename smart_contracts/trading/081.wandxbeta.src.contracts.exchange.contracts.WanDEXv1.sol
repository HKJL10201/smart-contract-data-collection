/*  
    Base Code is from ZeroEx
    Copyright 2017 ZeroEx Inc. 
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at 
        http://www.apache.org/licenses/LICENSE-2.0 

    @author Dinesh
    DECENTRALIZED MULTI COIN DERIVATIVE CONTRACTS
*/
pragma solidity ^0.4.13;
 
import "./base/Token.sol";
import "./base/SafeMath.sol";

/// @title WanDex - An exchange facilitates creating derivaives of ERC20 tokens
/// @author Dinesh
contract WanDEXv1 is SafeMath{ 
    address public owner;
    struct AssetOrder {
        address  seller;
        address buyer;
        address[] sellerToken;
        address[] buyerToken;
        address feeReceipient;
        uint[] sellerTokenAmount;
        uint[] buyerTokenAmount;
        uint sellerFee;
        uint buyerFee;
        uint expirationTimestampInSec;
        bytes32 orderHash; 
    }
 
    event LogFill(address indexed seller, address indexed buyer, address feeReceipient,
        address[] sellerTokens, address[] buyerToken, uint[] sellerTokenAmount, uint[] buyerTokenAmount,
        uint paidsellerFee, uint paidbuyerFee, bytes32 indexed tokens, bytes32 orderHash);
      
    /* Constructor*/
    function WanDEXv1() {
        owner = msg.sender;
    }  
    
    function transfer(address token, address from, address to, uint value) returns (bool) {
        assert(Token(token).transferFrom(from, to, value));
        return true;
    }  
    /* Core Exchange functions */
    function fillAssetOrder(address[] sellerTokens, uint[] sellervalues, address[] buyerTokens, uint[] buyerValues, address[3] orderAddresses, uint[4] orderValues) 
        returns (uint) {
            AssetOrder memory order = AssetOrder({
            seller: orderAddresses[0],
            buyer: orderAddresses[1],
            feeReceipient: orderAddresses[2],
            sellerToken: sellerTokens,
            buyerToken: buyerTokens,
            sellerTokenAmount: sellervalues,
            buyerTokenAmount: buyerValues,
            sellerFee: orderValues[0],
            buyerFee: orderValues[1],
            expirationTimestampInSec: orderValues[2],
            orderHash: getOrderHash(sellerTokens, sellervalues, buyerTokens, buyerValues, orderAddresses, orderValues) 
        });     
        bool isDone = true;
        // Move Maker tokens first
        for (uint i = 0; i < sellerTokens.length; i++) {
            if (!isDone) {
                return 0;
            }
            isDone = Token(order.sellerToken[i]).transferFrom(order.seller, order.buyer, order.sellerTokenAmount[i]); 
        }
        // Move Taker Tokens first 
        for (i = 0; i < buyerTokens.length; i++) {
             if (!isDone) {
                return 0;
            }
            isDone = Token(order.buyerToken[i]).transferFrom(order.buyer, order.seller, order.buyerTokenAmount[i]); 
        }
         LogFill(order.seller, order.buyer, order.feeReceipient, order.sellerToken, order.buyerToken, order.sellerTokenAmount,order.buyerTokenAmount, order.sellerFee, order.buyerFee, sha3(order.sellerToken, order.buyerToken), order.orderHash); 
        return 1;
    }  

    function verifyOrderHashes(address[] sellerTokens, uint[] sellervalues, address[] buyerTokens, uint[] buyerValues, address[3] orderAddresses, uint[4] orderValues, bytes32 hash) public  constant  returns (bool) {
        AssetOrder memory order = AssetOrder({
            seller: orderAddresses[0],
            buyer: orderAddresses[1],
            feeReceipient: orderAddresses[2],
            sellerToken: sellerTokens,
            buyerToken: buyerTokens,
            sellerTokenAmount: sellervalues,
            buyerTokenAmount: buyerValues,
            sellerFee: orderValues[0],
            buyerFee: orderValues[1],
            expirationTimestampInSec: orderValues[2],
            orderHash: getOrderHash(sellerTokens, sellervalues, buyerTokens, buyerValues, orderAddresses, orderValues) 
        });     
        return order.orderHash == hash;
    } 

    function getLength(address[] sellerTokens) constant returns (uint len) {
        len = sellerTokens.length;
    } 

    function getItem(address[] sellerTokens, uint index) constant returns (address item) {
        item = sellerTokens[index];
    }

    function getOrderHash(address[] sellerTokens, uint[] sellervalues, address[] buyerTokens, uint[] buyerValues, address[3] orderAddresses, uint[4] orderValues) constant returns (bytes32 orderHash) {
        return sha3(
            address(this), 
            orderAddresses[0], // seller
            orderAddresses[1], // buyer
            sellerTokens, // seller token
            buyerTokens, // buyer token
            orderAddresses[2], // fee receipient
            sellervalues, // seller token amount
            buyerValues, // buyer token amount
            orderValues[0], // seller fee
            orderValues[1], // buyer fee
            orderValues[2], // expirationTimestampInSec
            orderValues[3] // salt
        );
    }  
}