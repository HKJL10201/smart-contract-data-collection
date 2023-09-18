pragma solidity ^0.8.9;

import "./Storage.sol";
import "../interfaces/IOwnedProxy.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * ONLY USED ON THE UNIT TESTS
 */
contract ProductsV1 is Storage {
    using Counters for Counters.Counter;

    mapping(uint256 => address) public products;

    address private storeAddress;

    constructor() {}

    modifier onlyOwner {
        require(msg.sender == IOwnedProxy(address(this)).getOwner(), "Only owner is allowed");
        _;
    }

    function initialize(bytes memory _data) external payable onlyOwner {
        (address _storeAddress) = abi.decode(_data, (address)); 
        require(_storeAddress == address(0xf02A9d12267581a7b111F2412e1C711545DE217b), "STORE_EMPTY");

        storeAddress = _storeAddress;
        _uintStorage["ninja"] = 1234;
        _boolStorage["initialized"] = true;
    }

    function ninja() public view returns (uint256) {
        return _uintStorage["ninja"];
    }

    function initialized() public view returns (bool) {
        return _boolStorage["initialized"];
    }

    function testAddProduct(address _productAddress) external payable {
        products[_counterStorage["productCount"].current()] = _productAddress;
        _counterStorage["productCount"].increment();
    }

    function getLastProduct() public view returns (address) {
        return products[_counterStorage["productCount"].current() - 1];
    }

    function getCount() public view returns (uint256) { // new function
        return _counterStorage["productCount"].current();
    }

    function getStoreAddress() public view returns (address) {
        return storeAddress;
    }
}