pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;

import './helpers/SafeMath.sol';
import "./ERC721BasicToken.sol";
import "./Ownable.sol";

contract InvoiceTapContract is Ownable, ERC721BasicTokenContract {
    using SafeMath for uint256;
    
    struct Invoice {
        uint256 bolID;
        uint256 basePrice;
        uint256 discount;
        string status;
        uint256 createdAt;
    }
    
    struct Bid {
        uint256 bolID;
        address bidder;
        uint256 amount;
        uint256 createdAt;
    }
    
    event InvoiceAdded (
        uint256 bolId,
        uint256 basePrice,
        uint256 discount
    );
    event BidAdded(
        uint256 indexed _bolID,
        address indexed bidder,
        uint256 amount,
        uint256 created
    );
    
    mapping (uint256 => Invoice) invoices;
    Bid[]  public bids;
    uint256[] public submittedInvoices;
    mapping(address => uint256[]) bidsOfUser;
    mapping(uint256 => uint256[]) bidsOfInvoice;
    mapping(address => mapping(uint256 => bool)) hasUserBidOnInvoice;
    mapping(address => mapping(uint256 => uint256)) userBidOnInvoice;
    
    constructor(string _name, string _symbol) ERC721BasicTokenContract(_name, _symbol) public {
            
    }
    
    /** internal **/

    function _bidExists(uint256 bidId) internal view returns (bool) {
        if (bids.length == 0) {
            return false;
        }
        return bids[bidId].createdAt > 0;
    }
    
    function _isSenderisOwner(uint256 bidId) internal view returns (bool) {
        if (bids.length == 0) {
            return false;
        }
        return bids[bidId].bidder == msg.sender;
    }
    
    function _updateBid(uint256 bidId, uint256 amount) internal returns(uint256) {
        Bid storage _bid = bids[bidId];
        if (_bid.createdAt > 0) {
            _bid.amount = amount;
        }
        emit BidAdded(_bid.bolID, _bid.bidder, _bid.amount, _bid.createdAt);
        return bidId;
    }
    
    function _createBid(uint256 _bolID, uint256 amount) internal returns(uint256 bidId) {
        Bid memory _bid = Bid({
            bolID: _bolID,
            bidder: msg.sender,
            amount: amount,
            createdAt: now
        }); 
        
        bidId = bids.push(_bid) - 1;
        bidsOfUser[msg.sender].push(bidId);
        bidsOfInvoice[_bolID].push(bidId);
        userBidOnInvoice[msg.sender][_bolID] = bidId;
        hasUserBidOnInvoice[msg.sender][_bolID] = true;
        emit BidAdded(_bid.bolID, _bid.bidder, _bid.amount, _bid.createdAt);
        return bidId;
    }
    
    function _createInvoice(uint256 _bolID, uint256 _basePrice, uint256 _discount) public returns (uint256 tokenId) {
        require(!isBOLSubmitted(_bolID));
        Invoice memory _invoice = Invoice({
            bolID: _bolID,
            basePrice: _basePrice,
            discount: _discount,
            status: '',
            createdAt: now
        });
        invoices[_bolID] = _invoice;
        _mint(msg.sender, _bolID);
        submittedInvoices.push(_bolID);
        emit InvoiceAdded(_bolID, _basePrice, _discount);
        return _bolID;
    }
    
    function _updateInvoice(uint256 _bolID, uint256 _discount) public returns (uint256 tokenId) {
        Invoice storage _invoice = invoices[_bolID];
        if(_invoice.createdAt > 0) {
            _invoice.discount = _discount;
        }
        emit InvoiceAdded(_invoice.bolID, _invoice.basePrice, _invoice.discount);
        return _bolID;
    }
    
     /** anyone can call these functions**/
     
    function createInvoice(uint256 _bolID, uint256 _basePrice, uint256 _discount) public returns (uint256 bolID) {
        Invoice storage _invoice = invoices[_bolID];
        if (_invoice.createdAt > 0) {
            return _updateInvoice(_bolID, _discount);
        }
        return _createInvoice(_bolID, _basePrice, _discount);
    }    
    

    function bid(uint256 _bolID, uint256 amount) public returns (uint256 bidId) {
        //require(bills[billId].createdAt > 0);
        
        if (hasUserBidOnInvoice[msg.sender][_bolID]) {
            bidId = userBidOnInvoice[msg.sender][_bolID];
            return _updateBid(bidId, amount);
        }

        return _createBid(_bolID, amount);
    }
    
    function viewInvoice(uint256 _bolID) public view returns(Invoice) {
        return invoices[_bolID];
    }
    
    function hasUserAlreadyBid(address _bidder, uint256 _bolID) public view returns (bool){
        return hasUserBidOnInvoice[_bidder][_bolID];
    }
    
    function getBidsOnInvoice(uint256 _bolID) public view returns(uint256[]){
        return bidsOfInvoice[_bolID];
    }
    
    function getBidsOfUser(address _bidder) public view returns(uint256[]){
        return bidsOfUser[_bidder];
    }
    
    function totalBids() public view returns(uint256) {
        return bids.length;
    }
    
    function totalBills() public view returns(uint256) {
        return submittedInvoices.length;
    }
    
    function showBid(uint256 bidId) public view returns(uint256 billId, address bidder, uint256 amount, uint256 createdAt) {
        return (bids[bidId].bolID, bids[bidId].bidder, bids[bidId].amount, bids[bidId].createdAt);
    }
    
    function showBidOnInvoice(address _bidder, uint256 _bolID) public view returns(uint256 billId, address bidder, uint256 amount, uint256 createdAt) {
        bool hasBid = hasUserBidOnInvoice[_bidder][_bolID];
        if (hasBid) {
            uint256 bidId = userBidOnInvoice[_bidder][_bolID];
            Bid memory _bid = bids[bidId];
            return (_bid.bolID, _bid.bidder, _bid.amount, _bid.createdAt);
        }
    }
    
    function getSubmittedInvoices() public view returns (uint256[]) {
        return submittedInvoices;
    }
    
    function getSubmittedInvoice(uint256 _bolID) public view returns(uint256 bollID, uint256 basePrice, uint256 discount, bool isApplied) {
        Invoice storage _invoice = invoices[_bolID];
        if (_invoice.createdAt > 0) {
            return (_invoice.bolID, _invoice.basePrice, _invoice.discount, hasUserAlreadyBid(msg.sender, _bolID));
        }
    }
    
    function isBOLSubmitted(uint256 bolID) public view returns(bool) {
        Invoice storage _invoice = invoices[bolID];
        return _invoice.createdAt > 0;
    }
    
    function removeBid(uint256 _bolID) public returns(bool) {
        uint256 _bidID = userBidOnInvoice[msg.sender][_bolID];
        delete bids[_bidID];
        userBidOnInvoice[msg.sender][_bolID] = 0;
        hasUserBidOnInvoice[msg.sender][_bolID] = false;
        return true;
    }
    
}










