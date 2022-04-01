pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

// Storage
import "./storage/WtStorage.sol";
import "./storage/WtConstants.sol";
import "./modifiers/WtModifier.sol";


// NFT（ERC721）
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";


contract TicketFactory is ERC721Full, WtStorage, WtConstants {

    uint256 ticketCap = 100;
    string _tokenURI;

    constructor(
        string memory name, 
        string memory symbol,
        uint tokenId,
        string memory tokenURI
    ) 
        ERC721Full(name, symbol)
        public 
    {
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _tokenURI = tokenURI;
    }


    function testFunc() public returns (bool) {
        return WtConstants.CONFIRMED;
    }

    function _totalSupply() public view returns (uint256) {
        return totalSupply();
    }


    // @notice owner address of ERC721 token which is specified
    // @param _ticketId is tokenId
    function _ownerOf(uint _ticketId) public returns (address) {
        return ownerOf(_ticketId);
    }


    function mint() public returns (bool)  {
        require (ticketCap <= 100, "Ticket is sold out!");
        
        uint256 _tokenId = _totalSupply() + 1;
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        // Save Ticket data
        uint256 _sellingPrice = 100000;
        registerTicketPrice(_tokenId, _sellingPrice);
    }

    // @dev This function is used in case of calling mint() function on external contract.
    function mintOnExternalContract(address _callAddress) public returns (bool)  {
        require (ticketCap <= 100, "Ticket is sold out!");
        
        uint256 _tokenId = _totalSupply() + 1;
        _mint(_callAddress, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        // Save Ticket data
        uint256 _sellingPrice = 100000;
        registerTicketPrice(_tokenId, _sellingPrice);
    }


    function _transferTicketFrom(address _from, address _to, uint256 _ticketId) public returns (bool) {
        transferFrom(_from , _to, _ticketId);
    }


    /***
     * @notice - This function is for registering price of ticket
     ***/
    function registerTicketPrice(uint256 _ticketId, uint256 _sellingPrice) public returns (bool) {
    //function registerTicketPrice(address adminAddr, uint256 sellingPriceOfTicket) public returns (bool) {
        PurchasableTicket storage ticket = purchasableTickets[_ticketId];
        //PurchasableTicket storage ticket = purchasableTickets[adminAddr];
        ticket.ticketId = _ticketId;
        ticket.forSale = true;
        ticket.sellingPrice = _sellingPrice;
        ticket.isIssued = false;
        ticket.issuedSignature = '';
        // PurchasableTicket memory ticket = PurchasableTicket({ 
        //                                        forSale: true , 
        //                                        sellingPrice: sellingPriceOfTicket 
        //                                   });

        emit RegisterTicketPrice(ticket.ticketId,
                                 ticket.forSale, 
                                 ticket.sellingPrice, 
                                 ticket.isIssued,
                                 ticket.issuedSignature);

        return WtConstants.CONFIRMED;
    }
    
    function getTicketPrice(uint256 _ticketId) public view returns (uint256) {
        PurchasableTicket memory ticket = purchasableTickets[_ticketId];
        return ticket.sellingPrice;
    }


    /***
     * @notice - Issue on ticket after it buy ticket by someone
     ***/    
    function issueOnTicket(uint256 _ticketId, string memory _walletConnectSignature) public returns (bool) {
        PurchasableTicket storage ticket = purchasableTickets[_ticketId];

        // Check whether this ticket is signatured or not
        require (ticket.isIssued == false, "This ticket is already bought and signatured");
        
        ticket.isIssued = true;
        ticket.issuedSignature = _walletConnectSignature;
        ticket.issuedTimestamp = block.timestamp;

        emit IssueOnTicket(_ticketId, 
                           ticket.isIssued, 
                           ticket.issuedSignature,
                           ticket.issuedTimestamp);

        return WtConstants.CONFIRMED;
    }


    function saveAddtionalIssuedInfo(
        uint256 _ticketId, 
        address _ticketOwner, 
        string memory _issuedTxHash
    ) public returns (bool) {
        PurchasableTicket storage ticket = purchasableTickets[_ticketId];
        ticket.ticketOwner = _ticketOwner;
        ticket.issuedTxHash = _issuedTxHash;

        emit SaveAddtionalIssuedInfo(_ticketId, 
                           ticket.ticketOwner, 
                           ticket.issuedTxHash);

        return WtConstants.CONFIRMED;
    }
    


    /***
     * @notice - Get ticket status from struct of PurchasableTicket
     ***/  
    function ticketStatus(uint256 _ticketId) 
    public
    view 
    returns (uint256 ticketId,
             bool forSale, 
             uint256 sellingPrice,
             bool isIssued,
             string memory issuedSignature,
             address ticketOwner,
             uint256 issuedTimestamp,
             string memory issuedTxHash) 
    {
        PurchasableTicket storage ticket = purchasableTickets[_ticketId];

        return (ticket.ticketId,
                ticket.forSale,
                ticket.sellingPrice,
                ticket.isIssued,
                ticket.issuedSignature,
                ticket.ticketOwner,
                ticket.issuedTimestamp,
                ticket.issuedTxHash);
    }
    

}
