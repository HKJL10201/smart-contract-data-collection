pragma solidity ^0.6.4;

import "./ItemManager.sol";
//Creates instance of an item so each product has a unique address
contract Item {
    uint public priceInWei;
    uint public index;
    uint public pricePaid;

    ItemManager parentContract;
    constructor(ItemManager _parentContract, uint _priceInWei, uint _index) public {
        priceInWei = _priceInWei;
        index = _index; 
        parentContract = _parentContract;
    }

    //Fallback function to receive payments externally
    receive() external payable {
        require(msg.value == priceInWei, "Sorry! Only full payments allowed...");
        require(pricePaid == 0, "You've already paid for this item...");
        pricePaid += msg.value;
        //use a low level function to reduce gas fees and return a boolean to indicate its success, rather than .transfer()
        //Using "triggerFunction()" function signature. returns two values - bool for success and value. 2300 gas is used according to documentation.
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "Transaction was insuccessful. Canceling...");
    }
    
    fallback() external payable {}
}