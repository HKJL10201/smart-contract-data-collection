//SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";

contract lottery{

    using SafeMath for uint;

    // --------------------------------- INITIAL DECLARATIONS ---------------------------------

    //Instance of token contract
    ERC20Basic private token;

    //Owner & contract address
    address payable public owner;
    address public thisContract;

    //Number of tokens
    uint public created_tokens = 700000;

    event tokens_bought(uint, address);
    
    //Constructor 
    constructor() public {
        token = new ERC20Basic(created_tokens);
        owner = msg.sender;
        thisContract = address(this);
    }

    // --------------------------------- TOKEN MANAGEMENT ---------------------------------------

    //Restrict to contract's owner 
    modifier OwnerOnly(address _address) {
        require(_address == owner, "This function is restricted to the contract's owner.");
        _;
    }
    
    //Get token price
    function GetTokenPrice(uint _numTokens) internal pure returns(uint){
        return _numTokens.mul(1 ether);
    }
    
    //Token creation
    function CreateTokens(uint _numTokens) public OwnerOnly(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    //Buy tokens
    function BuyTokens(uint _numTokens) public payable{
        //Get contract's token balance
        uint balance = AvailableTokens();

        //Check availability of tokens
        require(_numTokens <= balance, "Not enough tokensavailable. Buy less tokens.");
        
        //get tokens price
        uint price = GetTokenPrice(_numTokens);

        //Check amount of eth payed
        require(msg.value >= price, "Buy less tokens or pay more ETH :)");

        //Refund change
        uint returnValue = msg.value.sub(price);
        msg.sender.transfer(returnValue);

        //Transfer tokens to buyer
        token.transfer(msg.sender, _numTokens);

        //Event
        emit tokens_bought(_numTokens, msg.sender);

    }

    //Get number of available tokens in contract
    function AvailableTokens() public view returns(uint){
        return token.balanceOf(thisContract);
    }

    //Get the balance of tokens in the lottery jackpot
    function Jackpot() public view returns(uint){
        return token.balanceOf(owner);
    }

    //Let participants know how many tokens they have
    function MyTokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    // --------------------------------- LOTTERY ---------------------------------------

    //Ticket price in tokens
    uint public ticketPrice = 5; 

    //Participants -> Ticket numbers
    mapping(address => uint[]) idParticipantTickets;

    //Ticket numbers -> participants
    mapping(uint => address) ticketWho;

    //Random number
    uint randNonce = 0;

    //Generated tickets
    uint[] tickets;

    //Events
    event buy_ticket(uint, address);
    event winner_ticket(uint);
    event refunded_tokens(uint, address);

    //Buy lottery ticket
    function BuyTicket(uint _tickets) public{
        //Get total price
        uint total_price = _tickets.mul(ticketPrice);

        //Check amount of tokens
        require(total_price <= MyTokens(), "You need to buy more tokens first!.");

        //Transfer tokens to owner (owner is the jackpot)
        token.transfer_lottery(msg.sender, owner, total_price);

        //Assign a random ticket number to buyer
        for(uint i=0; i < _tickets; i++){
            /*
                Take current time, msg.sender and a nonce o gnerate a random number,
                convert to hash and then to uint. %10000 to take only last 4 numbers (0-9999).
            */
            uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10000;

            //Save tickets data
            tickets.push(random);
            idParticipantTickets[msg.sender].push(random);
            ticketWho[random] = msg.sender;
        }        

        //Event
        emit buy_ticket(_tickets, msg.sender);
    }

    //Get tickets bought by participant
    function MyTickets() public view returns(uint[] memory){
        return idParticipantTickets[msg.sender];
    }

    //Pick a random winner
    function WinnerPicker() public OwnerOnly(msg.sender){
        //Check if tickets were bought
        require(tickets.length > 0, "No tickets were bought.");

        //Take a random number from bought tickets
        uint length = tickets.length;
        uint array_position = uint(uint(keccak256(abi.encodePacked(now))) % length);
        uint winner = tickets[array_position];

        //Event
        emit winner_ticket(winner);

        //Get winner's address
        address winner_address = ticketWho[winner];

        //Send tokens jackpot to winner
        token.transfer_lottery(msg.sender, winner_address, Jackpot());
    }

    //Exchange tokens for ETH (refund or winner claiming prize)
    function GetEth(uint _numTokens) public payable returns(uint){
        //_numTokens must be > 0
        require(_numTokens > 0, "You need an amount of tokens greater than 0");

        //Participant must have that amount of tokens
        require(_numTokens >= MyTokens(), "Not enough tokens in your wallet.");

        //Participant returns tokens
        //Lottery pays returned tokens
        token.transfer_lottery(msg.sender, thisContract, _numTokens);
        msg.sender.transfer(GetTokenPrice(_numTokens));

        //Event
        emit refunded_tokens(_numTokens, msg.sender);
    }





}