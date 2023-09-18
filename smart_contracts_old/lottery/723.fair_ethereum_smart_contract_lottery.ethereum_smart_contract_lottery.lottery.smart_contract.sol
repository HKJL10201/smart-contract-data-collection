// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Gambling {

    // bet status:
    uint constant STATUS_WIN = 1;
    uint constant STATUS_LOSE = 2;
    uint constant STATUS_PENDING = 3;
    
    //game status:
    uint constant STATUS_STARTED = 1;
    uint constant STATUS_COMPLETE = 2;
    
    //the 'bet' structure
    struct Bet {
      uint betValue;
      address addr;
      uint status;
    }
    
    //the 'game' structure
    struct Game {
      uint256 gameValue;
      uint outcome;
      uint status;
      uint numOfBets;
      Bet[] bets;
      uint id;
      address creatorAddress;
    }
    
    mapping(uint => Game) games;
    uint gameID = 0;
    uint lastID;
    Game game;
    
    //fallback function
    fallback() external {}
    
    //function to create game. It have to be called one time per constructed contract and right after construction 
    function createGame(uint _numOfBets) public payable {
        require(msg.value != 0, "You have to invest more than 0 eth!");
        require (_numOfBets >= 2, "Number of participants have to be 2 or more!");
        game.gameValue = msg.value;
        game.outcome = 0;
        game.status = STATUS_STARTED;
        game.numOfBets = _numOfBets;
        delete game.bets;
        game.bets.push(Bet(msg.value, msg.sender, STATUS_PENDING));
        gameID += 1;
        game.id = gameID;
        lastID = gameID;
        game.creatorAddress = msg.sender;
        games[gameID] = game;
    }
    
    // function to participate game
    function takeBet(uint _gameID) public payable { 
        //requires the taker to make the same bet amount 
        require(games[_gameID].status == STATUS_STARTED, "Game didn't start or completed!");
        require(msg.value >= games[_gameID].gameValue/games[_gameID].bets.length, "You investment have to be greater then or equal to average of former investments!");
        games[_gameID].gameValue += msg.value;
        games[_gameID].bets.push(Bet(msg.value, msg.sender, STATUS_PENDING));
        if(games[_gameID].bets.length == games[_gameID].numOfBets){
            generateGameOutcome(_gameID);   
            payout(_gameID);
        }
    }

    //function to transfer game value to winner
    function payout(uint _gameID) private {
        checkPermissions(msg.sender, _gameID);
        require(games[_gameID].status == STATUS_COMPLETE, "Game didn't complete yet");
        for (uint b = 0; b < games[_gameID].bets.length; b++) {
            if (games[_gameID].bets[b].status == STATUS_WIN) {
                payable(games[_gameID].bets[b].addr).transfer(games[_gameID].gameValue);
            }
        }
    }
    
    // function to randomly generate game outcome
    function generateGameOutcome(uint _gameID) private {
        checkPermissions(msg.sender, _gameID);
        games[_gameID].status = STATUS_COMPLETE;
        Bet[] memory tempArrBets = games[_gameID].bets;
        // generate random number: (array of bets, current block miner’s address and current block timestamp as input for hash function)
        games[_gameID].outcome = uint(keccak256(abi.encode(tempArrBets, block.coinbase, block.timestamp)))%games[_gameID].numOfBets;
        // winner is address in bet with index equal to outcome 
        for(uint j = 0; j < games[_gameID].bets.length; j++){
            if (j==games[_gameID].outcome){
                games[_gameID].bets[j].status = STATUS_WIN;
            }
            else {
                games[_gameID].bets[j].status = STATUS_LOSE;
            }
        }
    }
    
    // function to check if request sender is game participant
    uint signalExists;
    function checkPermissions(address sender, uint _gameID) private {
     //only the originator or taker can call this function
        signalExists = 0;
        for (uint i = 0; i < games[_gameID].bets.length; i++) {
            if (games[_gameID].bets[i].addr == sender){
                signalExists = 1;
            }
        }
        require(signalExists == 1, "Your address is not participant address!");  
    }

    function getLastID() public view returns(uint){
        return lastID;
    }

    // function to get total game value invested until the moment of the function call     
    function getGameValue(uint _gameID) public view returns(uint){
        return games[_gameID].gameValue;
    }
    
    // function to get number of bets until the moment of the function call 
    function getCurrentNumOfBets(uint _gameID) public view returns(uint){
        return games[_gameID].bets.length;
    }
    
    // function to get amount that we have to invest to enter game
    function getAmountToEnterGame(uint _gameID) public view returns (uint){
        require(games[_gameID].status == STATUS_STARTED, "Amuont requested to participate is unavailable to view, because the game is no longer open.");
        if (games[_gameID].bets.length > 0){
            return games[_gameID].gameValue/games[_gameID].bets.length;
        }
        else{
            return 0;
        }
    }

    // function to get maximum number of bets that can participate game    
    function getGameCapacity(uint _gameID) public view returns (uint) {
        return games[_gameID].numOfBets;
    }
    
    // function to get currently status of game (completed or still open)
    function getGameStatus(uint _gameID) public view returns (string memory){
        if (games[_gameID].status == STATUS_COMPLETE){
            return "Game completed";
        }
        else{
            return "Game is still open";
        }
    }
    
    // function to get address of game creator
    function getCreatorAddress(uint _gameID) public view returns (address){
        return games[_gameID].creatorAddress;
    }
    
    // function to get current game bets
    function getCurrentGameBets(uint _gameID) public view returns (Bet[] memory){
        return games[_gameID].bets;
    }
    
    // function to get index of bet with request sender address 
    function getMyIndex(uint _gameID) public view returns (uint myIndex){
        myIndex = games[_gameID].numOfBets; //impossible index as default
        for (uint p = 0; p < games[_gameID].bets.length; p++){
            if (games[_gameID].bets[p].addr == msg.sender){
                myIndex = p;
            }
        }
        if (myIndex == games[_gameID].numOfBets){
            require(1 == 0, "You are not participant!");
        }
    }
    
    // function to get winning index and address of bet with that index
    function getGameOutcome(uint _gameID) public view returns (uint winningIndex, address winnerAddress){
        //checkPermissions(msg.sender);
        require(games[_gameID].status == STATUS_COMPLETE, "Game didn't complete yet");
        for (uint k = 0; k < games[_gameID].bets.length; k++){
            if (games[_gameID].bets[k].status == STATUS_WIN){
                winningIndex = k;
                winnerAddress = games[_gameID].bets[k].addr;
            }
        }
    }

}
