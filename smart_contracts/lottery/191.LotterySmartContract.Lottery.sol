pragma solidity ^0.4.11;

contract Lottery {

    mapping(uint => address) public gamblers;// A mapping to store ethereum addresses of the gamblers
    uint8 public player_count; //keep track of how many people are signed up.
    uint256 public ante; //how big is the bet per person (in ether)
    uint8 public required_number_players; //how many sign ups trigger the lottery
    address owner; // owner of the contract
    mapping(address => uint) public bet;// A mapping to store ethereum addresses and chosenNumber
    uint lotteryNumber;
    
    modifier AdminOnly() 
    {
        if (msg.sender == owner) 
        {
            _ ; // continue
        }
    }


    //constructor
    function Lottery(uint _ante, uint8 _required_number_players, uint lottery_number){
        owner = msg.sender;
        player_count = 0;
        ante = _ante;
        required_number_players = _required_number_players;
        lotteryNumber = lottery_number;
    }


// function when someone gambles a.k.a sends ether to the contract
function buy (uint chosenNumber) payable {
    // No arguments are necessary, all
    // information is already part of
    // the transaction. The keyword payable
    // is required for the function to
    // be able to receive Ether.

    // If the bet is not equal to the ante, send the
    // money back.
    if(msg.value / 1000000000000000000 != ante) throw; // give it back, revert state changes, abnormal stop
    if(player_count == required_number_players) throw; // If enough participants then stop accepting
    if(chosenNumber < 1 || chosenNumber > 100) throw;
    player_count +=1;

    gamblers[player_count] = msg.sender;
    bet[msg.sender] = chosenNumber;
}

function draw() AdminOnly{
    
    uint closestNum = 100;
    address winner = 0;
    
    for(uint i = 1; i<=player_count ;i++){
        uint betNum = bet[gamblers[player_count]];
        uint diff = 0;
        if(bet[gamblers[player_count]] > lotteryNumber){
            diff = betNum - lotteryNumber;
        }else if(lotteryNumber > betNum){
            diff = lotteryNumber - betNum;
        }
        
        if(betNum < closestNum){
            closestNum = betNum;
            winner = gamblers[player_count];
        }
    }
    
    winner.send(ante * player_count);
}

}
