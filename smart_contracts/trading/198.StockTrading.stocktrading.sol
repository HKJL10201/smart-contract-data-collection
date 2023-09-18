// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract StockTrading{
   struct Stock{
       uint256 price;
       uint256 quantity;
   }
    mapping(string => Stock) public stocks;
    mapping(address => mapping(string => uint256)) public balances;

    address public hedgeFund;

    event StockBought(address buyer, string StockName, uint256 price, uint256 quantity);
    event StockSold(address seller, string StockName, uint256 price, uint256 quantity);
     
     constructor() {
         hedgeFund = msg.sender;
     }

     modifier onlyHedgeFund() {
         require(hedgeFund == msg.sender, "Only Owner can call this function");
         _;
     }

     function buyStock(string memory stockName, uint256 quantity) public payable{
         Stock memory stock = stocks[stockName];
         require(stock.price > 0, "Stock does not exist");
         require(msg.value >= stock.price * quantity, "Insufficient funds");

         balances[msg.sender] [stockName] += quantity;
         emit StockBought(msg.sender, stockName, stock.price, quantity);
     }

     function sellStock(string memory stockName, uint256 quantity) public{
         Stock memory stock = stocks[stockName];
         require(stock.price > 0, "Stock does not exist");
         require(balances[msg.sender] [stockName] >= quantity, "Insufficient stock balance");

         balances[msg.sender] [stockName] -= quantity;
         payable(msg.sender).transfer(stock.price * quantity);
         emit StockSold(msg.sender, stockName, stock.price, quantity);

     }
     function addStock(string memory stockName, uint256 quantity, uint256 price) public onlyHedgeFund{
         Stock memory stock = stocks[stockName];
         require(stock.price == 0, "Stock already exists");
         stocks[stockName] = Stock(price, quantity);
     }
     
       function updateStockPrice(string memory stockName, uint256 price) public onlyHedgeFund{
       Stock memory stock = stocks[stockName];
       require(stock.price > 0, "Stock does not exist.");

       stocks[stockName].price = price;
   }

   function withdrawFunds() public onlyHedgeFund {
       payable(hedgeFund).transfer(address(this).balance);
   }

}
