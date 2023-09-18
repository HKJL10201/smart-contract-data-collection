pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract TradeShift {
    struct Product {
        uint id;
        address payable creator;
        string name;
        uint256 cost;
    }

    struct Trade {
        uint id;
        address payable creator;
        Product product;
        bool complete;
    }

    Product[] public products;
    Trade[] public trades;

    uint public productId;
    uint public tradeId;

    address payable public manager;

    constructor() public payable{
        manager = msg.sender;
    }

    function createProduct(string memory name, uint256 cost) public  {
        Product memory newProduct = Product({
           id: productId,
           creator: msg.sender,
           name: name,
           cost: cost
        });

        productId++;
        products.push(newProduct);
    }

    function getProducts() public view returns(Product[] memory) {
        return products;
    }

    function getTrades() public view returns(Trade[] memory) {
        return trades;
    }

    function buyProduct(uint productId) public payable {
      uint index;
      for (index = 0; index < products.length; index++) {
         if (products[index].id == productId) {

            require(msg.value == products[index].cost);

            Trade memory newTrade = Trade({
                id: tradeId,
                creator: msg.sender,
                product: products[index],
                complete: false
            });
            trades.push(newTrade);
            tradeId++;

            products[index].creator.transfer(msg.value/5);
            manager.transfer((msg.value*4)/5);
         }
      }
    }

    function verifyTrade(uint tradeId) public payable {
        require(msg.sender == manager);
        uint index;
        for (index = 0; index < trades.length; index++) {
            if (trades[index].id == tradeId) {
                require(!trades[index].complete);
                require(msg.value <= ((trades[index].product.cost*4)/5));
                trades[index].product.creator.transfer(msg.value);
                trades[index].complete = true;
            }
         }
    }
}
