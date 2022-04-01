//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract ProductPurchase {
    address admin;
    
    struct Product {
        uint256 code;
        string name;
        uint256 price;              // price of single product in wei;
        uint256 quantity;
    }
    
    mapping(uint256 => Product) public products;
    
    mapping(address => uint256) public usersTokenAmount;
    
    constructor() {
        admin = msg.sender;
    }
    
    function addProduct(uint256 _code, string memory _name, uint256 _price, uint256 _quantity) view public {
        require(msg.sender == admin, "Only Admin can add the product");
        
        Product memory _product = products[_code];
        _product.code = _code;
        _product.name = _name;
        _product.price = _price;
        _product.quantity = _quantity;
    }
    
    function removeProduct(uint256 _code) public {
        require(msg.sender == admin, "Only Admin can remove the product");
        
        delete products[_code];
    }
    
    function buyProduct(uint256 _code, uint256 _quantity) payable public {
        require(products[_code].quantity >= _quantity, "Requested product quantity not available");
        
        // Check if user has the balance to buy the product or not
        uint256 _totalPrice = products[_code].price * _quantity;
        
        require(_totalPrice == msg.value, "Not enough balance to buy the product");
        
        usersTokenAmount[msg.sender] += _quantity;
        
        products[_code].quantity -= _quantity;
    }
    
    function withdrawAmount() public payable {
        payable (admin).transfer(address(this).balance);
    }
}
