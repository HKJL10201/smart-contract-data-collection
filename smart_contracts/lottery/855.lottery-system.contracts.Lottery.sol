pragma solidity ^0.4.0;

contract Lottery{
    address owner;
    address winner;
    uint constant price = 1 ether;
    address[] public participantsAddresses;
    bool lotteryOn;
    
    struct TicketHolder{
        uint[] guess;
        uint tokensObtained;
    }
    
    mapping (address => TicketHolder) public holderOfAddress;
    bytes32 WinningGuess;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyWinner{
        require(msg.sender == winner);
        _;
    }
    
    function Lottery(uint winningGuess) public{
        owner = msg.sender;
        lotteryOn = true;
        WinningGuess = keccak256(winningGuess);
    }
    
    function buyLotteryTickets() public payable{
        require(lotteryOn == true);
        uint tickets = msg.value/price;
        msg.sender.transfer(msg.value - tickets*price);
        holderOfAddress[msg.sender].tokensObtained += tickets;
    }
    
    function makeGuess(uint guess) public{
        require(guess>0 && guess<1000000 && holderOfAddress[msg.sender].tokensObtained > 0 && lotteryOn == true);
        holderOfAddress[msg.sender].guess.push(guess);
        holderOfAddress[msg.sender].tokensObtained -= 1;
        participantsAddresses.push(msg.sender);
    }
    
    function winnerAddress() returns(address){
        for(uint i = 0; i < participantsAddresses.length; i++)
        {
            TicketHolder holder = holderOfAddress[participantsAddresses[i]];

            for(uint j = 0; j < holder.guess.length; j++) 
            {
                  if (keccak256(holder.guess[j]) == WinningGuess)
                  {
                      return participantsAddresses[i];
                  }
            }
        }
        return owner;
    } 
    
    function closeGame() public onlyOwner returns(address){
        lotteryOn = false;
        winner = winnerAddress();
        return winner;
    }
    
    function getPrice() public onlyWinner{
        msg.sender.transfer(address(this).balance/2);
        owner.transfer(address(this).balance/2);
    }
}