pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

import "./helpers/SafeMath.sol";
import "./ERC721BasicToken.sol";
import "./Bill.sol";
import "./BAMToken.sol";

contract BAMTokenContractInterface {
    function hasBAMAccess (address _whitelistedAddress, string _companyId) public view returns (bool);
}

contract BAMBillOfLadingContract is BillContract, ERC721BasicTokenContract{
    using SafeMath for uint256;
    BAMTokenContractInterface public assetToken; 
    
    modifier onlyWithAccess (string _comapnyId) {
        require(hasBAMAccess(_comapnyId));
        _;    
    }
    
    constructor(string _name, string _symbol, BAMTokenContractInterface _tokenAddress) ERC721BasicTokenContract(_name, _symbol) public {
        assetToken = _tokenAddress;
    }
    
    function hasBAMAccess (string _comapnyId) public view returns (bool){
        return assetToken.hasBAMAccess(msg.sender, _comapnyId);
    }
    
    function setTokenAddress (BAMTokenContractInterface _tokenAddress) public onlyOwner returns (address){
        require(_tokenAddress != address(0));
        assetToken = _tokenAddress;
        return assetToken;
    }
    
    function getTokenAddress () public view returns (BAMTokenContractInterface) {
        return assetToken;
    }
    
    function createBill(string quoteId, string _companyId) onlyWithAccess(_companyId) public returns (uint256 _tokenId){
        bills.length++;
        Bill storage bill = bills[bills.length - 1];
        bill.quoteId = quoteId;
        bill.carrier_address = msg.sender;
        bill.companyId = _companyId;
        
        // for (uint i = 0; i < items.length; i++){
        //     bill.items.push(items[i]);
        // }
        
        _tokenId = bills.length - 1;
        _mint(msg.sender, _tokenId);
        emit BillCreated(msg.sender, _tokenId, quoteId);
    }
    
    function addItem(uint256 _billId, Item item) onlyOwnerOf(_billId) public returns (Item[]) {
        Bill storage bill = bills[_billId];
        bill.items.push(item);
        return bill.items;
    }
}