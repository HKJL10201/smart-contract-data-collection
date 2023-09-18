pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

import "./helpers/SafeMath.sol";
import "./Ownable.sol";

contract BillContract is Ownable{
    using SafeMath for uint256;
    
    struct Item {
        uint id;
        uint quantity;
        uint price;
        uint weight;
        string detail;
    }
    
    struct Bill {
        Item[] items;
        address carrier_address;
        string companyId;
        string quoteId;
    }
    
    Bill[] public bills;
    
    function getBillQuoteId(uint256 _billId) public view returns(string quoteId) {
        return bills[_billId].quoteId;
    }
    
    function getBillCompanyId(uint256 _billId) public view returns(string companyId) {
        return bills[_billId].companyId;
    }
    
    function getBillCarrierAddress(uint256 _billId) public view returns(address carrier_address) {
        return bills[_billId].carrier_address;
    }
    
    function getBillItems(uint256 _billId) public view returns(Item[]) {
        return bills[_billId].items;    
    }
    
    function getBillInfo(uint256 _billId) public view returns(string quoteId, address carrier_address, Item[] items) {
        return (
            bills[_billId].quoteId,
            bills[_billId].carrier_address,
            bills[_billId].items
        );
    }
    
    event BillCreated (
        address indexed carrier_address,
        uint256 tokenId,
        string quoteId
    );
}