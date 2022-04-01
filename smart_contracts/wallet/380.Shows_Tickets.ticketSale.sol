pragma solidity ^0.4.23;
contract ticketSale {

    uint ticketPrice;
    uint totalTickets;
    uint ticketsSold;
    bytes private __uriBase="Insert URL here http://www.ticketSale.com/tokens/";
    address saleOwner;
    
    
    mapping(address=>uint) adresstoQuantity;
    mapping(uint=>address) ticketIdtoOnwner;

    event ticketIssued(uint _ticketID,address ticketOwner,string ticketURL);
 
    constructor(uint _price,uint _quantity,string _uriBase) public{
        ticketPrice= _price;
        totalTickets= _quantity;
        __uriBase = bytes(_uriBase);
        saleOwner=msg.sender;
        ticketsSold=0;
    }
    
    function buyTicket(uint _noOfTickets) external payable{
        require(msg.value==(_noOfTickets*ticketPrice));
        require(ticketsSold+_noOfTickets<=totalTickets);
        for(uint i=0;i<_noOfTickets;i++)
        {
             ticketIdtoOnwner[ticketsSold]=msg.sender;
             emit ticketIssued(ticketsSold,msg.sender,ticketURI(ticketsSold));
             ticketsSold++;
             
        }
        adresstoQuantity[msg.sender]+=_noOfTickets;
    }
    
    function trasferTicket(address _to,uint _ticketId) external {
        require(_to != msg.sender);
        require(_to != address(0));
        require(ticketIdtoOnwner[_ticketId]==msg.sender);
        ticketIdtoOnwner[_ticketId]==_to;
        adresstoQuantity[msg.sender] -= 1;
        adresstoQuantity[_to] += 1;    
    }
    function getTicketCount() public view returns (uint){
        return adresstoQuantity[msg.sender];
    }
    function getTicketOwner(uint _ticketId) public view returns (address){
        return ticketIdtoOnwner[_ticketId];
    }
    function _isValidTicket(uint _ticketId) internal view returns (bool){
        if(ticketIdtoOnwner[_ticketId]!=address(0)){
            return true;
        }
        return false;
    }

    function ticketURI(uint _ticketId) public view returns (string){
    require(_isValidTicket(_ticketId));
    uint maxLength = 78;
    bytes memory reversed = new bytes(maxLength);
    uint i = 0;
 
    while (_ticketId != 0) {
        uint remainder = _ticketId % 10;
        _ticketId /= 10;
        reversed[i++] = byte(48 + remainder);
    }

    bytes memory s = new bytes(__uriBase.length + i);
    uint j;
    for (j = 0; j < __uriBase.length; j++) {
        s[j] = __uriBase[j];
    }
    for (j = 0; j < i; j++) {
        s[j + __uriBase.length] = reversed[i - 1 - j];
    }
    return string(s);
}
    
}