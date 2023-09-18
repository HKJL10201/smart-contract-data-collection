pragma solidity ^0.4.23;

contract Roll2Win{

    address public owner;

    /*
        players hashmap with address as key and PlayerMetadata as structure in it
    */
    address[] public playersArray;

    mapping (address => PlayerMetadata ) public players;
    uint32 public playerCount;
    uint32 public targetPosition = 9;

    /*
        Four status to maintain the states of the player
        Won - player has won the game, so no further playing for the room
        Lost - player has lost the game, that means he cant play anymore
        Rolling - player is rolling the dice, that means no other player can roll the dice for the room
        Done - player has done rolling, now next player can roll the dice
    */
    enum Status {Added, Won, Lost, Rolling, Done}
    
    Status boardStatus;

    /*
        PlayerMetadata is struct which contains all the metadata information about the single player in an individual room
        betAmount - betting amount player puts in the game
        inBoardOrder - Position on the board like Ist, IInd, IIIrd at start
        currentPosition - Current Index of the cell in the game
        targetPosition - Target Index of the cell in the game
        count - number of rolled dice from the player
        player - address of the player in the room
     */
    
    struct PlayerMetadata{
        uint betAmount;
        uint inBoardOrder;
        uint currentPosition;
        uint count;
        Status status;
        address player;
        bool isPresent;
    }
    
    //variable which holds the total betting amount
    uint256 public totalBetAmount=0;

    /**
    All different kinds of events which will get generated in the game
     */

    event Added(address player);
    event Won(address player);
    event Lost(address player);
    event Rolling(address player);
    event Done(address player);

    //when there is no sufficient balance then you can not play
    event NotSufficientBalance(address player, uint money);

    //when owner tried to enter into the game
    event OwnerNotAllowed(address player);
    
    //event if room is full
    event RoomIsFull(uint totalPlayers);

    //when other person is rolling, then other can not roll in the same room
    event NoRollingAllowed(address player, uint money);
    
    //event for the boardstatus change
    event BoardStatusEvent(Status boardstatus, address player);
    
    //event for the number after rolling the dice
    event DiceRolled(uint8 diceNumber);
    
    //event if player already exists in the system
    event PlayerExists();
    
    //event if not enough players in the room, then wait
    event WaitForPlayers();
    /*
        All the modifiers which will be used in the game
     */
    modifier checkMinimumBalance(){
        require(msg.value > 0,"minimum amount needed to play the game");
        _;
    }


    constructor() public{
        playerCount = 0;
        owner = msg.sender;
    }
    
    modifier restricted {
        require(msg.sender == owner);
        _;
    }
    
    modifier isDiceRolling{
        require(uint(Status.Rolling) != uint(boardStatus));
        _;
    }
    
    modifier isRoomFullModifier{
        require(isRoomFull() == false,"Romm is full, can not join");
        _;
    }

    function addPlayer() public checkMinimumBalance isRoomFullModifier payable{
        
            bool isPlayerExists = playerExists(msg.sender);
            if(!isPlayerExists){
                //add the player to the players mapping
                players[msg.sender] = PlayerMetadata(msg.value, playerCount+1, 0, 0, Status.Added, msg.sender, true);
                
                //add the plyaers to the players array
                playersArray.push(msg.sender);
                //increase the betAmount
                totalBetAmount = totalBetAmount + msg.value;
                
                //increase the player count 
                playerCount = playerCount + 1;
        
                //emit the add event after player gets added
                emit Added(msg.sender);
            }else{
                //its not reverting the balance as the player should be penalize for occupying the room more than once
                emit PlayerExists();
                
            }

    }

    function playerExists(address addr) view public returns(bool){
            if(players[addr].isPresent){
                return true;
            }else{
                return false;
            }   
    }

    function isOwnerFunc() view public returns(bool){
        if(msg.sender == owner){
            return true;
        }
        return false;
    }
    
    function isGameStart() view public returns(bool){
        if(playerCount == 2){
            return true;
        }else{
            return false;
        }
    }

    function isRoomFull() view public returns(bool){
        if(playerCount >= 2){
            return true;
        }
        return false;
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getPlayerBetAmount(address add) public view returns(uint256){
        return players[add].betAmount;
    }

    function getPlayerInfo(address add) public view returns(uint inBoardOrder, uint betAmount, uint currentPosition, uint count, uint status ){
        inBoardOrder = players[add].inBoardOrder;
        betAmount = players[add].betAmount;
        currentPosition = players[add].currentPosition;
        count = players[add].count;
        status = uint(players[add].status);
        
        return (inBoardOrder, betAmount, currentPosition, count, status);
    }

    function rollDice() public isDiceRolling {
        
            bool isGameReady = isGameStart();
            if(isGameReady){
                //set the status of the board to rolling
                boardStatus = Status.Rolling;
                emit BoardStatusEvent(boardStatus,msg.sender);
                
                uint8 diceNumber = generateRandomNumber();
                emit DiceRolled(diceNumber);
                
                players[msg.sender].count = players[msg.sender].count+1;
                players[msg.sender].currentPosition = players[msg.sender].currentPosition + diceNumber;
                boardStatus = Status.Done;
                if(players[msg.sender].currentPosition >= targetPosition){
                    transferMoney();
                    resetBoard();   
                    emit Won(msg.sender);
                }
            }else{
                //wait for other players event fired
                emit WaitForPlayers();
            }
    }
    
     
    
    function transferMoney() private {
        players[msg.sender].player.transfer(address(this).balance);
    }

    function resetBoard() public{
        for (uint i=0; i<playersArray.length; i++) {
            delete(players[playersArray[i]]);
        }
        playerCount = 0;
    }
    
    function generateRandomNumber() private view returns (uint8) {
        //for simplicity only, considering the block.timestamp which can be replaced by some  
        //universal random number generator smart contract
        uint8 diceNumber = uint8(uint256(keccak256(block.timestamp, block.difficulty))%7);
        return diceNumber;
    }
    
    function() private payable{
        revert("Some error occured");
    }
}