// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract Lottery {

    //current state of the betting round
    enum State {
        IDLE,
        BETTING
    }

    address payable[] public players;
    State public currentState = State.IDLE;
    uint public maxNumPlayers; //betcount
    uint public moneyRequiredToBet;  //betsize
    uint public houseFee;
    address public admin;


    constructor(uint fee) {
        require(fee > 1 && fee < 99 , "fee should be between 1ETH and 99ETH");
        admin = msg.sender;
        houseFee = fee;
    }

    modifier inState(State state){
        require(state == currentState, "Current state does not allow this");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function createBet(uint numPlayers, uint betMoney) external inState(State.IDLE) onlyAdmin() {
        maxNumPlayers = numPlayers;
        moneyRequiredToBet = betMoney;
        currentState = State.BETTING;
    }

    function _randonModulo(uint modulo) view private returns (uint) {
        //generating a random number
        uint randonNumber;
        randonNumber = uint( keccak256( abi.encodePacked(block.difficulty, block.timestamp)));
        randonNumber = randonNumber % modulo;
        return randonNumber;
    }

    //if cancel the bet, send back the money to the players
    function cancel() external inState(State.BETTING) onlyAdmin() {
        for(uint i = 0; i < players.length ;i ++){
            players[i].transfer(moneyRequiredToBet);
        }
        delete players;
        currentState = State.IDLE;
    }

    //allow the players to bet
    function bet() external payable inState(State.BETTING) {
        require(msg.value == moneyRequiredToBet, "Can only bet exactly the money");
        players.push(payable(msg.sender));
        //if we reach the max number, we decide the winner
        if(players.length == maxNumPlayers){
            //pick a winner
            //send the money to the winner
            uint winner = _randonModulo(maxNumPlayers);
            players[winner].transfer((moneyRequiredToBet * maxNumPlayers) * (100 - houseFee) / 100);
            currentState = State.IDLE;
            delete players;
        }
    }
}