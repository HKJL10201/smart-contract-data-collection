pragma solidity ^0.4.24;

/**
 * TODO: change dependece of random oracle from block to players(require changes on transaction process).
 */
contract Lottery{
    enum State { bingo, no_prize, pending} // state for a ticket
    
    struct Ticket {
        address player; // address this ticket belongs to
        uint time; // timestamp
        uint lottery; // the bet number
        State state; // the state
    }

    struct Prize {
        uint winningNumber;
        uint pool;
        uint winners;
    }

    Ticket[] tickets; // all tickets ascending by time
    Prize[] prizes; // prizes for each round
    mapping (address => uint[]) addressBook; // holds the mapping between address and ticket indices
    address croupier; // dealer bot in our casino
    uint interval; // interval between each drawing
    uint prizeValue; // value for one ticket

    uint drawTime; // upcoming drawing time
    uint head; // head ticket for current round
    address[] winners; // all winners in a round

    // restrict for contract croupier
    modifier onlyByOwner() { 
        require(msg.sender == croupier, "Access denied.");
        _;
    }

    // restrict for bet
    modifier restrictBet() {
        require(now < drawTime, "Time out.");
        require(msg.value == prizeValue, "Invalid ticket price.");
        _;
    }

    // restrict for draw time
    modifier restrictDraw() {
        require(now >= drawTime, "Bet not yet ended.");
        _;
    }

    // constructor
    constructor () public {
        croupier = msg.sender;
        head = 0;
        interval = 1 hours;
        drawTime = now + interval;
        prizeValue = 0.1 ether;
        prizes[prizes.length++] = Prize(0, 0, 0);
    }

    function () public payable {}

    // @dev Bet.
    // @para number The number you choose to bet.
    // @return ticket_id Corresponding id for this ticket.
    function bet(uint number) public payable restrictBet() returns (uint ticket_id) {
        ticket_id = tickets.length++;
        tickets[ticket_id] = Ticket(msg.sender, block.timestamp, number, State.pending);
        addressBook[msg.sender].push(ticket_id);
    }

    function getRandom() private view returns (uint rand){
        return block.timestamp % 100;
    }

    // @dev Draw the lottery
    function draw() public restrictDraw() returns (uint) {
        delete winners;
        uint winningNumber = getRandom(); // RNG
        uint pool = address(this).balance;
        uint bonus = 0;
        // search for winners
        for(; head < tickets.length; head++){
            if(tickets[head].lottery == winningNumber ){ // bingo
                tickets[head].state = State.bingo;
                winners[winners.length++] = tickets[head].player;
            }
            else{ // no prize
                tickets[head].state = State.no_prize;
            }
        }
        // give out bonus
        if(winners.length != 0){
            bonus = address(this).balance / winners.length;
            for(uint i = 0; i < winners.length; i++){
                winners[i].transfer(bonus);
            }
        }

        prizes[prizes.length++] = Prize(winningNumber, pool, winners.length);
        drawTime = now + interval;
        return prizes[prizes.length - 1].winningNumber;
    }

    // @dev show current result.
    // @return Prize(winningNumber, pool, winners)
    function showCurrentResult() public view returns (uint winningNumber, uint pool, uint winnersNum) {
        winningNumber = prizes[prizes.length - 1].winningNumber;
        pool = prizes[prizes.length - 1].pool;
        winnersNum = prizes[prizes.length - 1].winners;
    }
    
    // @dev show history results.
    // @return Prize[]
    function showHistoryResults() public view returns (uint[] winningNumberArray, uint[] poolArray, uint[] winnersArray) {
        winningNumberArray = new uint[](prizes.length);
        poolArray = new uint[](prizes.length);
        winnersArray = new uint[](prizes.length);
        for(uint i = 0; i < prizes.length; i++){
            winningNumberArray[i] = prizes[i].winningNumber;
            poolArray[i] = prizes[i].pool;
            winnersArray[i] = prizes[i].winners;
        }
    }

    // @dev show tickets by one's address
    // @return Tickets[]
    function showByAddress() public view returns (uint[] time, uint[] lottery, uint[] state) {
        time = new uint[](addressBook[msg.sender].length);
        lottery = new uint[](addressBook[msg.sender].length);
        state = new uint[](addressBook[msg.sender].length);
        for(uint i = 0; i < addressBook[msg.sender].length; i++){
            time[i] = tickets[addressBook[msg.sender][i]].time;
            lottery[i] = tickets[addressBook[msg.sender][i]].lottery;
            state[i] = uint(tickets[addressBook[msg.sender][i]].state);
        }
    }
}