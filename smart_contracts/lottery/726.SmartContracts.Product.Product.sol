pragma solidity 0.4.21;


contract Product {
    address creator;
    address owner;
    address pid;
    uint salePrice = 1 ether;
    uint updateFee = 1 finney;
    bool readOnly = true;
    bool forSale = false;

    mapping (string => string) attributes;

    function Product() public {
        creator = msg.sender;
        owner = msg.sender;
        pid = address(this);
    }
    
    function toggleForSale() public payable {
        require(msg.value >= updateFee);
        require(!readOnly);
        forSale = !forSale;
    }
    
    function setReadOnly() public payable {
        require(msg.value >= updateFee);
        readOnly = !readOnly;
    }
    
    function isForSale() public view returns (bool) {
        return forSale;
    }
    
    function isReadOnly() public view returns (bool) {
        return readOnly;
    }
    
    function buy(address newOwnerAddress) public payable {
        require(msg.value >= salePrice);
        require(forSale); 
        owner = newOwnerAddress;
    }
    
    function setAttribute(string Key, string Value) public payable {
        require(msg.value >= updateFee);
        require(!isReadOnly()); 
        attributes[Key] = Value;
    }
    
    function getAttribute(string Key) public view returns (string){
        return attributes[Key];
    }
    
}
