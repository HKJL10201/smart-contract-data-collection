// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './wallet.sol';

contract Dex is Wallet {

    using SafeMath for uint256;

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;

    //function to return current order book
    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    //function to create limit order
    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public{
        if(side == Side.BUY){
           require(balances[msg.sender]["ETH"] >= amount.mul(price), "ETH balance must be greater than or equal to buy order value!");
        }
        else if(side == Side.SELL){
           require(balances[msg.sender][ticker] >= amount, "Token balance must be greater than or equal to sell order value!");
        }

        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(
            Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)
        );

        //Bubble sort for both order books
        uint i = orders.length > 0 ? orders.length - 1 : 0;

        if(side == Side.BUY){
            while(i > 0){
                if(orders[i - 1].price > orders[i].price) {
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }
        else if (side == Side.SELL){
             while(i > 0){
                if(orders[i - 1].price < orders[i].price) {
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }

        nextOrderId++;
    }

    //function to create market order
    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
        if(side == Side.SELL){
            //checks if seller has enough of token to sell
            require(balances[msg.sender][ticker] >= amount, "Insufficient token balance");
        }

        uint orderBookSide;
        if(side == Side.BUY){
            orderBookSide = 1;
        }
        else if (side == Side.SELL){
            orderBookSide = 0;
        }

        Order[] storage orders = orderBook[ticker][orderBookSide];

        uint totalFilled = 0;

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++){
            uint leftToFill = amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled);
            uint filled = 0;

            if(availableToFill > leftToFill){
                filled = leftToFill;
                //fill entire market order
            }
            else{
                filled = availableToFill;
                //fill as much as is available in order[i]
            }
            //update totalFilled
            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);

            uint cost = filled.mul(orders[i].price);

            //Execute trade & shift balances
            if(side == Side.BUY){
                //msg.sender = buyer
                //verify buyer has enough ETH for transaction
                require(balances[msg.sender]["ETH"] >= cost, "Not enough ETH for transaction");

                //adjust balances of msg.sender
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);

                //adjust balances of seller
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
            }
            else if(side == Side.SELL){
                //msg.sender = seller
                //verify seller has enough tokens for transaction checked at beginning of function
                
                //adjust balances of msg.sender
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(filled);
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(cost);

                //adjust balances of buyer
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(cost);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(filled);
            }
            
        }

        //remove 100% filled orders from orderbook
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            //remove top element in order array by overwriting filled orders
            for (uint256 i = 0; i < orders.length -1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }

    }

}
