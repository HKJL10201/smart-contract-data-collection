
pragma solidity >=0.7.0 <0.9.0;
 
 
contract Lottery{
    
    struct Participant{
        string name;
    }
    
    // public variables
    mapping(address => Participant) public participants;
    address[] public participants_addr;
    string public lottery_name;
    bool public active;
    uint public ticket_price;
    address owner;
    address public winner;


 
    // Constructor
    function Constructor(string memory _name, uint  _price) public{
        owner = msg.sender;
        lottery_name = _name;
        active = true;
        ticket_price  = _price;
        
        
    }
    
    // Gets called to buy a ticket.
    function buyTicket(string memory _name) payable public {
        require(active);
        require(msg.value == ticket_price);
        
        Participant memory participant = Participant(_name);
        participants_addr.push(msg.sender);
        participants[msg.sender] = participant;
    }
    
    function drawLottery() public{
        require(msg.sender == owner);
        active = false;
        winner = participants_addr[0];
        payable(winner).transfer(ticket_price * participants_addr.length - 10);
    }

    
    
    
}