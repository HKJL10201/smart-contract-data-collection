pragma solidity ^0.8.0;

contract PlayerInterface {
    string playerName;
    address playerAddress;
    string country;
    string Type;
    uint performance;
    uint basePrice;
   
    bool public sell;
   
   
    constructor (string memory _playerName, address _playerAddress, string memory _country, string memory _Type, uint _performance, uint _basePrice){
        playerName = _playerName;
        playerAddress = _playerAddress;
        country = _country;
        Type = _Type;
        performance = _performance;
        basePrice = _basePrice;
    }
   
    function setSell() public{
        sell = !sell;
    }
   
}
