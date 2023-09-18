pragma solidity ^0.4.24;

/**
 * @title VirtualLotto
 * @dev Lotto llows users to bet on which number will be selected by a random number generator
 */
contract VirtualLotto {
    
    address public owner;
    // minimal bet on ticket 
    uint public minBet; 
    // amount of bets per one cycle
    uint public betsPerRound;
    
    // ticket with picked number, bet amount and bool status
    struct Ticket {
        uint number;
        uint amount;
        bool isWinner;
    }
    
    // all players that participate in lotto
    address[] public players;
    // all player`s tickets
    mapping(address => Ticket[]) public playerTickets;
    
    // amount of bets
    uint public betCount = 0;
    // amount of rounds
    uint public roundCount = 0;

    event RoundConcluded(uint length, address[] winners, uint luckyNumber, uint prize);

    /**
    * @param _minBetInFinney Minimal bet on ticket 
    * @param _betsPerRound Amount of bets per one cycle
    */
    constructor(uint _minBetInFinney, uint _betsPerRound) public {
        
        owner = msg.sender;
        
        minBet = _minBetInFinney * 1 finney;
        betsPerRound = _betsPerRound;
    }
    
    /**
    * @dev Function accepts integer between 1 and 10 inclusive, and accepts any 
    * amount of ether (minimum bet)
    * @param number Picked number
    */
    function pickNumber(uint number) public payable {
        
        require(1 <= number && number <= 10);
        require(msg.value >= minBet);
        require(playerTickets[msg.sender].length < 4);
        require(isSameTicket(msg.sender,number) == false);
        
        if (playerTickets[msg.sender].length == 0) {
            
            players.push(msg.sender);
        }
        
        playerTickets[msg.sender].push(Ticket({
            number: number,
            amount: msg.value,
            isWinner: false
        }));
        
        betCount++;

        // if amount of bets equals a limit then finalize a round
        if (betCount >= betsPerRound) {
        
            finalizeRound(getLuckyNumber());
        }
    }
    
    /**
    * @dev Function gets a winners and distributes money 
    * @param luckyNumber Generated number
    */
    function finalizeRound(uint luckyNumber) private {

        uint count = prepareWinners(luckyNumber);
        address[] memory winners = getWinners(count);
        uint prize;
        
        if (count > 0) {
            
            prize = address(this).balance / winners.length;
            distributePrize(prize, winners);
        }
        
        emit RoundConcluded(winners.length, winners, luckyNumber, prize);

        nextRound();
    }
    
    /**
    * @dev Function generates random number
    */
    function getLuckyNumber() private view returns (uint) {
        
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 10) + 1;
    }
    
    /**
    * @dev Function checks if player choose the same ticket
    * @param player Player addres
    * @param number Number of ticket
    */
    function isSameTicket(address player, uint number) private view returns (bool yes) {
        
        for (uint u = 0; u < playerTickets[player].length; u++) {
            if (playerTickets[player][u].number == number) {
                return true;
            }
        }
        
        return false;
    }

    /**
    * @dev Function sets the winner ticket to all players
    * @param luckyNumber Generated number
    */
    function prepareWinners(uint luckyNumber) private returns (uint count) {
        
        for (uint i = 0; i < players.length; i++) {
            for (uint u = 0; u < playerTickets[players[i]].length; u++) {
                if (playerTickets[players[i]][u].number == luckyNumber) {
                    playerTickets[players[i]][u].isWinner = true;
                    count++;
                }
            }
        }
        
        return count;
    }
    
    /**
    * @dev Function returns all winners
    * @param amount Amount of players that have winner ticket
    */
    function getWinners(uint amount) private view returns (address[] memory winners) {
        
        winners = new address[](amount);
        uint count;
        
        for (uint i = 0; i < players.length; i++) {
            for (uint u = 0; u < playerTickets[players[i]].length; u++) {
                if (playerTickets[players[i]][u].isWinner == true) {
                    winners[count] = players[i];
                    count++;
                }
            }
        }
        
        return winners;
    }

    /**
    * @dev Function returns amount of players that get tickets
    */
    function getPlayersAmount() public view returns (uint){
        return players.length;
    }

    /**
    * @dev Function return amount of tickets for player
    * @param i Index of player in array
    */
    function getPlayerTicketsAmount(uint i) public view returns (uint){
        return playerTickets[players[i]].length;
    }

    /**
    * @dev Function send money to the winners
    * @param prize Part of all money
    * @param winners Array of winners
    */
    function distributePrize(uint prize, address[] winners) private {
        
        for (uint i = 0; i < winners.length; i++) {
            winners[i].transfer(prize);
        }
    }

    /**
    * @dev Function clears data about last round and sets a new
    */
    function nextRound() private {
        
        for (uint i = 0; i < players.length; i++) {
            delete playerTickets[players[i]];
        } 
        
        players.length = 0;
        betCount = 0;
        roundCount++;
    }

    /**
    * @dev Function closes lotto
    */
    function kill() public {
        
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }

}