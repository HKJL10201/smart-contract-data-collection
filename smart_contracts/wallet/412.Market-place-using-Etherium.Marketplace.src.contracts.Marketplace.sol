pragma solidity ^0.5.0;


contract Marketplace {
    string public name;
    uint256 public productCount = 0;
    mapping(uint256 => Product) public products;

    // see there is this question, that we didnt create an object
    //of the product struct but when we are creating the mapping, that
    //object is created automatically as we see here it is made
    constructor() public {
        name = "The MarketPlace";
    }

    struct Product {
        uint256 id;
        string name;
        uint256 price;
        address payable owner;
        bool purchased;
    }
    event ProductCreated(
        uint256 id,
        string name,
        uint256 price,
        address payable owner,
        bool purchased
    );
    event ProductPurchased(
        uint256 id,
        string name,
        uint256 price,
        address payable owner,
        bool purchased
    );

    function createProduct(string memory _name, uint256 _price) public {
        //create the product
        //make sure the parameters are correct
        //trigger an event
        require(bytes(_name).length > 0, "doesnt work");
        require(_price > 0, "doesnt work buddy");
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _price,
            msg.sender,
            false
        );
        //see this is here we are making an object of structure and then we are storing it in an array
        emit ProductCreated(productCount, _name, _price, msg.sender, false);
    }

    function purchaseProduct(uint256 _id) public payable {
        // Fetch the product
        Product memory _product = products[_id];
        // Fetch the owner
        address payable _seller = _product.owner;
        // Make sure the product has a valid id
        require(_product.id > 0 && _product.id <= productCount);
        // Require that there is enough Ether in the transaction
        require(msg.value >= _product.price);
        // Require that the product has not been purchased already
        require(!_product.purchased);
        // Require that the buyer is not the seller
        require(_seller != msg.sender);
        // Transfer ownership to the buyer
        _product.owner = msg.sender;
        // Mark as purchased
        _product.purchased = true;
        // Update the product
        products[_id] = _product;
        // Pay the seller by sending them Ether
        address(_seller).transfer(msg.value);
        // Trigger an event
        emit ProductPurchased(
            productCount,
            _product.name,
            _product.price,
            msg.sender,
            true
        );
    }
}
/* the thing here is we dont know how many mappings are there in this
and if we try for a number higher than the mapping then it will
return the struct so for that we have to create a count of all the 
elements which are there in it
*/

//we use truffle migrate to deploy the code on the blockchain
