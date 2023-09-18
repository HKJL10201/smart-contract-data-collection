// SPDX-Licence-Identifier: UNLICENSED

pragma solidity ^0.8.15;

contract ecommerce {
    // Creating a product data type
    struct Product {
        string title;
        string description;
        address payable seller;
        uint256 productId;
        uint256 price;
        address buyer;
        bool delivered;
    }

    Product[] public products;

    event registered(string title, uint256 priductId, address seller);
    event baught(uint256 Productid, address buyer);
    event delivered(uint256 Productid);

    // For assigning unique productID
    uint256 counter = 1;

    // Making a manager
    address payable public manager;

    bool destroyed = false;

    // Modifier to check if the contract is destoryed or not!
    modifier isDestoryed() {
        require(!destroyed, "Contract does not exists");
        _;
    }

    constructor() {
        manager = payable(msg.sender);
    }

    // function to register products

    function registerProducts(
        string memory _title,
        string memory _desc,
        uint256 _price
    ) public isDestoryed {
        require(_price > 0, "Product price cannot be 0");
        Product memory tempProduct;
        tempProduct.title = _title;
        tempProduct.description = _desc;
        tempProduct.price = _price * 10**18;
        tempProduct.seller = payable(msg.sender);
        tempProduct.productId = counter;
        products.push(tempProduct);
        counter++;
        emit registered(_title, tempProduct.productId, msg.sender);
    }

    // function to buy product from the store
    function buy(uint256 _productId) public payable isDestoryed {
        // checking if the price enterd is exact amount of the product and if the seller is not the buyter
        require(
            products[_productId - 1].price == msg.value, // [_product-1] for matching index in products array
            "please Pay the exact price"
        );
        require(
            products[_productId - 1].seller != msg.sender,
            "Seller cannot be buyer"
        );
        products[_productId - 1].buyer = msg.sender;
        emit baught(_productId, msg.sender);
    }

    function delivery(uint256 _productId) public isDestoryed {
        require(
            products[_productId - 1].buyer == msg.sender,
            "Only buyer can track"
        );
        products[_productId - 1].delivered = true;
        products[_productId - 1].seller.transfer(
            products[_productId - 1].price
        );
        emit delivered(_productId);
    }

    // To destroy the smart contract when manager call destroy function
    function destroy() public {
        require(manager == msg.sender, "Only manager can do this!");
        manager.transfer(address(this).balance);
        selfdestruct(manager);
        destroyed = true;
    }

    // Transfer all the payment back to the buyer
    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
