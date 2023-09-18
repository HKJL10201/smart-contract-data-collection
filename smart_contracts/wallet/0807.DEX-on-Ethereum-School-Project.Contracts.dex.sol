//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
//pragma experimental ABIEncoderV2; was used in the lesson and may not be needed 
//for the current version of Solidity.

//We import the file with the wallet contract, 
//which are both in the same folder
import "./wallet.sol";

contract Dex is Wallet {

//We do not need to import Safemath since we already imported it in our wallet,
//which is ingerited in this contract.
    using SafeMath for uint256;
    

//We can make an enum for the 2 sides of the order book, buy & sell
//Beneath the surface, these are integers, BUY is 0, and SELL is 1
    enum Side {
        BUY,
        SELL
    }


//DATA FOR ORDER BOOK
//This STRUCT provides storage for orders
    struct Order {
        uint id;
        address trader;
        Side side;
//This Boolean can be used to choose buy or sell
// bool buyOrder; but an enum with a mapping is used instead
//A bytes32 string is used for the type of crypto asset to buy or sell
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled; //This amount increases as orders in the order book are done,
        //and completed orders are removed from the order book.
    }


// Counter that makes the order ids:
//It starts at zero, = 0, which you do not need to write
//This increases each time we make an order
    uint public nextOrderId = 0;
   
   //ORDER BOOK
//This order book mapping is a structure that
//points from a bytes32 string for the asset symbol, 
//since there is ab order book for each asset,
//to another mapping, which has a uint of 0 for BUY and 1 for SELL,
//each of which points to 1 of 2 sections of the order book 
//(or one might say a buy order book and a sell order book).
//This BUY or SELL section is an array.
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;


//This is a function for getting the order book data
//This is view, since we will just return data
//This returns the Order array.
//Side is for the BUY or SELL struct, and side is for they value chosen/input
//of BUY or SELL (called "side", since BUY and SELL made 2 sides of an order book).
    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
    //We change side to a uint with [uint(side)], to make 0 for BUY or 1 for SELL, and 
//side is connected with the Side enum, which has 0 for BUY and 1 for SELL
//In another contract, this can be called with inputs of, for example: bytes32("ETH")
//for the order book of that type of crypto, 
//and Side.BUY, for the BUY value of the enum called "Side"
        return orderBook[ticker][uint(side)];
    }
    
    //We make a function for people to add things to the order book
//When we add an order into the order book, 
//we need to put it in the right part of the order book, 
// It's said in the course that for the buy side the highest price is at the top or first
//& for the sell side the highest price is at the bottom or last
//We can sort the orders using a loop


//With Side side, you pick whch side of the order book you want to use, BUY or SELL.
//amount variable is amount of crypto that you want to buy or sell
//We can use our tests to build the code, for example an error if balance is too low

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public{
        if(side == Side.BUY){
            require(balances[msg.sender]["ETH"] >= amount.mul(price));
        }
        else if(side == Side.SELL){
//If I want to sell a particular number of tokens, I need to have them in my account,
//and for this require situation, price is not important.
            require(balances[msg.sender][ticker] >= amount);
        }
//We make an order object. We can start by getting the BUT or SELL side of the order book
//that we want. We can make a storage array called "orders". With storage, it does not
// save it in memory, it makes a reference 
//(= a connection between a particular variable and a particular object) 
//to an array in storage.
//We get it from the order book for the ticker 
//& for the particular side of the order book (BUY or SELL).
//The mapping points to an array with a particular order, 
//& we can get a reference to that array. This array is a set or list of orders.
//THese are either all buy orders or sell orders, connected with which one you choose.
//With this we can put our new order into this array.
//We make a new order by stating the id (_ for now) address of the trader msg.sender, side,
// ticker, amount, price
//We push the order into the orders array
//ORDER BOOK, WITH THE BUY ORDER SIDE OF THE ORDER BOOK:
        Order[] storage orders = orderBook[ticker][uint(side)];
          //ORDER:
        orders.push(
            Order(nextOrderId, msg.sender, side, ticker, amount, price, 0)
        );

        //Bubble sort
        //When we push the order into the array, it is put at the end of the array.
//To make it have the correct place in the series, we use a method called "bubble sorting"
//In this if code, we sort for BUY or SELL orders, but not both, since an order
//is BUY or SELL, but not both.

//BUBBLE SORT
//We start with a starting value of i
//orders.length > 0, in other words there is a value in the array, the array is not empty.
//order.length -1 is the index number of the last value in the array.
//IF thelength of the array is more than 0 (IF there is at least value in the array),
//THEN i is arrayName.length -1, in other words i is the last value in the array
//& IF the array is empty, THEN i = 0
//IF TRUE, i has this value: orders.length -1
//IF FALSE then the value is:  0
//i is the last value in the array
//We start at the end of the array, and we use a loop
//Different types of loops are used for buy and sell orders  
        uint i = orders.length > 0 ? orders.length - 1 : 0;
        if(side == Side.BUY){
            while(i > 0){
//IF the second to last price is more than the price of the last value,
//THEN stop, because to more sorting is needed for this array item.
                if(orders[i - 1].price > orders[i].price) {
                    break;
//"break" = "(of a block of code, etc.) to end, to stop being active"
//Stop the loop, because we do not need to sort the array items.
                }
                Order memory orderToMove = orders[i - 1];
//and in the orders array, the position of i - 1 is connected with i,
//therefore i moves to the position which i - 1 had, which is the next position before i,
//therefore i is moved one position before its earlier position, one position to the left.
//We overwrite the i value in the position of i - 1. 
                orders[i - 1] = orders[i];
//Then orders[i], which is the last value position in the array, is connected to orderToMove,
//which is the item that was next to & before i, and which was put in memeory, 
//which makes that item in memory become the last item in the array 
//(instead of the original i). We then overwrite the last position with i - 1 / orderToMove.
                orders[i] = orderToMove;
//We then decrease i. Therefore we do this action again with the value in the second to last
//position. Then, if there is a another loop action, we do it starting with the second to last
//array item. If repeated again, the i position has decreased again, therefore we start with
//the third to last array item, etc.
                i--;
            }
        }
//If an order is a SELL order, it is sorted in a a similar way to a BUY order.
//except with the opposite lower-higher arrangement of the series.
        else if(side == Side.SELL){
            while(i > 0){
                if(orders[i - 1].price < orders[i].price) {
                 //If the value before i has a higher price than i
                    break;   
                }
                
//We save a copy of orderToMove in memory, which is orders[i - 1],
//which is the second to last item in the array.
//The second to last item in the array is put in memory, and 
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }

        nextOrderId++; //with ++ we increase the order number with 1
    }
//We do not need a price because we just want to buy at the best available price
//We should loop through the order book, until either the market order is completely done, 
//or the order book is empty. 
//There is a connection between this finction and the filled variable in the struct.
//We need to get the buy or sell side of the order book.
//We need to match buy orders with sell orders, or match sell orders with buy orders.
//If the person making the morket order wants to buy, we need to match it with a sell order.
//Therefore we need to get the sell side of the order book. 
//It is the Order array, which is in storage 
//(so we do not need to provide this action with extra mamory).
    function createMarketOrder(Side side, bytes32 ticker, uint amount) public{
   //Message from course teacher: This should be put in an if instruction 
   //ONLY FOR SELL ORDERS
   //For buy market order we do not know the total price, until we have looped
   //because the price is the best available price, not a particular amount in the order
   //The ETH balance is checked for each exchange, and if multiple exchanges are needed 
   //to complete the order, the ETH balance is checked multiple times.
   //There can be an error message, for example "balance not enough"
        if(side == Side.SELL){
            require(balances[msg.sender][ticker] >= amount, "Insuffient balance");
        }
        
        uint orderBookSide;
   //For a SELL order we want to match with BUY.
        if(side == Side.BUY){
            orderBookSide = 1;
        }
        else{
            orderBookSide = 0;
        }
        
        
//Order is a struct. 
        Order[] storage orders = orderBook[ticker][orderBookSide];
        
        
//This is used for how much of the order has been done
        uint totalFilled = 0;
        
       //This is the entire market order, not just with this particular single loop.
        //This amount starts at zero, and when the market order is completed, the loop stops
        //How much is available in this order 
        //sub = subtracted by what has already been done in the order, orders[i].filled
        //order.amount - order.filled

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint leftToFill = amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled);
//An order in the order book might have been done before. 
//For example I can make a limit order for 10 LINK, then an order can take 5 of them, 
//& there is only 5 left, & that we keep track of with the filled variable in the Order struct.
//We can check about limit orders that have more or less than the market order: 
            uint filled = 0;
//This starts at zero
//We can check if availableToFIull > leftToFill
//WE FIND OUT HOW MUCH OF THE MARKET ORDER WE DO IN THIS PARTICULAR LOOP
            if(availableToFill > leftToFill){
   //This is for when the entire market order IS COMPLETED with the limit order

                filled = leftToFill; //Fill the entire market order  //since this is the maximum, if the available amount is 200
            //but the order is only 100, we do not want to exchange 200, only 100 is filled,
            //and then no more are available
            }
            else{ //availableToFill <=leftToFill
        //With this, the entire limit order is used for the exchange
        //USE AS MUCH CRYPTO AS IS AVAILABLE (IN THE LIMIT ORDER), AND DO PART OF THE MARKET ORDER
                filled = availableToFill; //Fill as much as is available in order[i]
                //For example we want 200, this order has 100, which we exchange
            }
//NOW THAT WE HAVE THE AMOUNT USED FOR THE ORDER IN THIS PARTICULAR LOOP, 
//WE CAN MAKE THE TOTAL AMOUNT DONE
            totalFilled = totalFilled.add(filled);
             //When we have the order book side, we can use our loop.
        //The order comes in with the function arguments. 
        //These arguments do not need to be saved, 
        //because the market order takes things out of the order book, and to make the exchange.
        //The market order does not go in the order book. Therefore we do not need to save it,
        //we just need to loop through the order book and match it with orders.
        //We can use a for loop or while loop for this.
        //We continue loop either until orders.length 
        //(until orders.length = through the entire order book) 
        //(teacher says this means we used every oRder in the order book)
        //or the market order is completed. When the order is completed, we can stop the loop.
        //We loop as long as totalFilled < amount (of crypto in the order)
        //The ends when i = order.length (we looped through entire order book) or
        //when totalFilled = amount.

//THIS LOOP WAS NOT FOUND IN THE LATER VERSION
  //This loop is in the order book:
      //for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) //i = index
  //HOW MUCH WE NEED TO EXCHANGE FOR THE ORDER find out how much we can fill from order [i]
  //The first time through the loop, thisis is equal to the amount variable,
  //after part of the order is done, we have totalFilled, and this can be used
  //to show the amount that still needs to be done in the order  
  //Update totalFilled   "sub" means "subtract"
        //uint leftToFill = amount.sub(totalFilled); //amount - totalFilled
    
    
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);


//This is different for a buy or sell market order
            if(side == Side.BUY){
                //Verify that the buyer has enough ETH to cover the purchase (require)
                //Make sure that buy market order has enough ETH for the exchange, for each exchange done.
//The price is often different for different orders. 
//Check filled.mul(orders[i].price for each row
//Check about enough ETH for the filled amount times the size of the order, (orders[i].price)
                require(balances[msg.sender]["ETH"] >= cost);
//Do the exchange & change the balances between buyer and seller.
//This happens in a buy order: 
//Transfer ETH from buyer to seller & transfer tokens from seller to buyer
//In the SELL side of the order book, msg.sender is the seller
//In the BUY side of the order book, msg.sender is the buyer

                //msg.sender is the buyer
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);
                
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
            }
            else if(side == Side.SELL){
                //Msg.sender is the seller
                balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
                
                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
            }
            
        }
            //Remove 100% filled orders from the orderbook
            
            //Remove 100% completed orders from the order book. 
//We need to delete values from a sorted array.
//We do this with a loop that starts at the beginning of the orders array, 
//and removes every completed order, overwriting it with the next array value
//(i replaced by i+1, with i being an array value's index number).
//The order book has orders with the best prices at the top of the order book 
//(beginning of array). These are completed first. 
//Therefore completed orders are all at the beginning of the array, and the loop can stop 
//at the first value of an order which is not yet completed.
//The following orders do not need to be checked, since they are also not completed.
//Also, for the loop to happen/continue, there must be at least 1 order in the order book,
//therefore the loop only happens while orders.length > 0
//We use 2 loops, the while loop, and withion that loop, a for loop.
//The for loop is used for overwriting an array value with the next value, i = i+1
//orders[0] is the first value in the array
//In the loop, at the last array value, there is no i + 1. 
//Therefore we need to stop the for loop at orders.length - 1, the 2nd to last array value.
//Then we have an extra copy of the last value / order in the array, 
//and we use the pop method to remove it. 
//When we have a value / order for an order that is not complete, the while loop also stops
//with && instructions, the first thing, before &&, is checked first (in this example orders.length > 0)
//Only if the first statement is true, will the program check the next thing, after &&
        while(orders.length > 0 && orders[0].filled == orders[0].amount){
            //Remove the top element in the orders array by overwriting every element
            // with the next element in the order list
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            
//After the for loop, when we have the the last value twice (original and copy), we use pop
            orders.pop();
        }
        
        //We can loop through the order book and remove 100% completed orders.
        
    }

}
