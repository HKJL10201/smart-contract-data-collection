pragma solidity ^0.5.0;


contract Marketplace {
    string public name;
    uint256 public productCount = 0;
    mapping(uint256 => Product) public products;

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

    constructor() public {
        name = "Dapp University Marketplace";
    }

    function createProduct(string memory _name, uint256 _price) public {
        require(bytes(_name).length > 0); // Require a valid name
        require(_price > 0);
        productCount++; // Increment product count
        products[productCount] = Product( // Create the product
            productCount,
            _name,
            _price,
            msg.sender,
            false
        );
        // Trigger an event
        emit ProductCreated(productCount, _name, _price, msg.sender, false);
    }

    function purchaseProduct(uint256 _id) public payable {
        Product memory _product = products[_id];
        address payable _seller = _product.owner;
        require(_product.id > 0 && _product.id <= productCount);
        require(msg.value >= _product.price); // Require that there is enough Ether in the transaction
        require(!_product.purchased); // Require that the product has not been purchased already
        require(_seller != msg.sender); // Require that the buyer is not the seller
        _product.owner = msg.sender; // Transfer ownership to the buyer
        _product.purchased = true; // Mark as purchased
        products[_id] = _product; // Update the product
        address(_seller).transfer(msg.value); // Pay the seller by sending them Ether

        emit ProductPurchased( // Trigger an event
            productCount,
            _product.name,
            _product.price,
            msg.sender,
            true
        );
    }
}
