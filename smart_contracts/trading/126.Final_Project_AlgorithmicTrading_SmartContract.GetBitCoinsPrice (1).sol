// SPDX-License-Identifier: UNLICIENSE
pragma solidity ^0.6.2;
import "github.com/provable-things/ethereum-api/blob/master/contracts/solc-v0.6.x/provableAPI.sol";

contract GetBitCoinsPrice is usingProvable {  
 
 
    address public owner;
 //   bytes32 public BTC=bytes32("BTC"); //32-bytes equivalent of BTC
    bytes32 public BTC;
 //   bytes32 public ETH=bytes32("ETH");
    bytes32 public ETH;
    

// tracking events
    event newOraclizeQuery(string description);
    event newPriceTicker(uint price);

    // constructor
    constructor()public payable {
       
        owner = msg.sender;

        
    }


    // method to place the oraclize queries
    function updatePrice() public returns(bool) {
        if (owner.balance > 0) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            
        
            ETH = provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price"); 


            BTC = provable_query("URL", "json(https://api.pro.coinbase.com/products/BTC-USD/ticker).price"); 
           

        }
        return true;
  
}


}
