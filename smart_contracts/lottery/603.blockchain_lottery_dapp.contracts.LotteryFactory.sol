pragma solidity ^0.5.8;

contract LotteryFactory {
    uint8 lottery_count;
    uint8 magic_number;
    uint8 total_guesses;
    uint balance;
    bool lottery_dead;
    modifier MinAnte {require (msg.value >= 0.25 ether, "Sending value must be >= 0.25 ETH"); _;}
    modifier DeadSpread {require (lottery_dead == true, "A Lottery already exists"); _;}
    event GuessMade();
    event LotteryWon(address);
    constructor() public {
        lottery_count = 0;
        lottery_dead = true;
        create_lottery();
    }
    function create_lottery() public DeadSpread {
        lottery_count += 1;
        lottery_dead = false;
        total_guesses = 0;
        magic_number = random();
    }
    function make_guess(uint8 player_guess) public payable MinAnte {
        emit GuessMade();
        balance += msg.value;
        total_guesses += 1;

        if(player_guess == magic_number) {
            lottery_dead = true;
            create_lottery();
            msg.sender.transfer(balance);
            balance = 0;
            emit LotteryWon(msg.sender);
        }
    }
    function get_lottery_count() public view returns (uint8) {return lottery_count;}
    function get_magic_number() public view returns (uint8) {return magic_number;}
    function get_total_guesses() public view returns (uint8) {return total_guesses;}
    function get_balance() public view returns (uint) {return balance;}
    function random() public view returns (uint8) { return uint8(uint256(keccak256(abi.encode(block.timestamp)))%9 + 1); }
}
