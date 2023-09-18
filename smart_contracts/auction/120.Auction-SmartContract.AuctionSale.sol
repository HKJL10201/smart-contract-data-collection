// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <=0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";

contract AuctionSale{

    struct Item{
        string itemNumber;
        string name;
        uint reservePrice;
    }
    struct quote{
        address bider;
        string itemNumber;
        uint quotePrice;
    }
    struct alloted{
        address bider;
        string itemNumber;
        uint quotePrice;
        uint reservePrice;
    }
    uint private serialNum;
    Item[] private itemArr;
    quote[] private quoteArr;

    mapping(string => alloted) public result;
    constructor(){
        serialNum =1;
    }
    
    function addItem(string memory _name, uint price) public {
        Item memory i;
        i.itemNumber = string(abi.encodePacked("Item_",Strings.toString(serialNum)));
        i.name = _name;
        i.reservePrice = price;
        itemArr.push(i);
        serialNum++;
    }

    function getItems() view public returns(Item[] memory){
        return itemArr;
    } 
    
    function doBid(string memory _itemNumber ,uint quoteVal) public{
        quote memory q;
        q.bider = msg.sender;
        q.itemNumber = _itemNumber;
        q.quotePrice = quoteVal;
        quoteArr.push(q);
    }

    function AuctionFinalize() public{
        for(uint i=0;i<itemArr.length;i++){
            uint maxQuote = itemArr[i].reservePrice;
            for(uint j=0; j<quoteArr.length; j++){
                if(maxQuote<quoteArr[j].quotePrice){
                    alloted memory a;
                    a.itemNumber =quoteArr[j].itemNumber;
                    a.quotePrice= quoteArr[j].quotePrice;
                    a.reservePrice = itemArr[i].reservePrice;
                    a.bider = quoteArr[j].bider;
                    result[quoteArr[j].itemNumber]= a;
                }
            }

        }
    }

    function getAuctionresult(string memory _itemNumber) view public returns(alloted memory){
        return result[_itemNumber];
    }
}