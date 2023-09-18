pragma solidity ^0.5.0;
import "./Dice.sol";


/*
1. First create dice using the Dice contract
2. Transfer both die to this contract using the contract's address
3. Use setBattlePair from each player's account to decide enemy
4. Use the battle function to roll, stop rolling and then compare the numbers
5. The player with the higher number gets BOTH dice
6. If there is a tie, return the dice to their previous owner
*/

/*
DiceBattle execution / test:
1. use account A to deploy Dice contract
2. use account A to deploy DiceBattle contract with arg (Dice contract address)
3. use account B to execute Dice function add dice with arg (1,2) and value 1 ether, becomes dice 0
4. use account B to execute Dice function transfer dice with arg (0, DiceBattle address)
5. use account B to execute DiceBattle function setBattlePair with arg (account C address, 0)
6. use account C to execute Dice function add dice with arg (3,4) and value 3 ether, becomes dice 1
7. use account C to execute Dice function transfer dice with arg (1, DiceBattle address)
8. use account C to execute DiceBattle function setBattlePair with arg (account B address, 1)
9. use account C to execute DiceBattle function battle with arg (1, 0, account C address, account B address)
10. use any account to execute DiceBattle function battleResults with arg (0) to see battle results, including dice1, dice2, player1, player2, winner, and if tie result
11. use any account to check Dice variable dices with arg (0), and with arg (1). The prev owner of both dice 0 and dice 1 should be the DiceBattle address, and the new owner should be the winner in step 10 or original owner if tie.
* in console can also see the diceId, newNumber and result event type (winResult, loseResult, tieResult)
* result event is relative to the account that executed battle function, as account C executed the battle, hence
* winResult - account C is owner of dice 0 and dice 1
* loseResult - account B is owner of dice 0 and dice 1
* tieResult - account B is owner of dice 0 and account C is owner of dice 1
*/

contract DiceBattle {
    Dice diceContract;
    mapping(address => address) battle_pair;

    // event selectedBattlePair();
    event tieResult();
    event winResult();
    event loseResult();

    // mapping (address => mapping (address => uint256)) public result;

    uint256 numBattleResults = 0;
    mapping(uint256 => battleResult) public battleResults;

    struct battleResult {
        uint256 diceId1;
        uint256 diceId2;
        address player1;
        address player2;
        address winner;
        bool tie;
    }

    function addBattleResult(
        uint256 diceId1,
        uint256 diceId2,
        address player1,
        address player2,
        address winner,
        bool tie
    )internal returns(uint256) {
        
        //new battleResult object
        battleResult memory newBattleResult = battleResult(
            diceId1,
            diceId2,
            player1,
            player2,
            winner,
            tie
        );
        
        uint256 newBattleResultId = numBattleResults++;
        battleResults[newBattleResultId] = newBattleResult; //commit to state variable
        return newBattleResultId;   //return new battleResultId
    }

    constructor(Dice diceAddress) public {
        diceContract = diceAddress;
    }

    // there is 1 Dice contract address and 1 DiceBattle contract address
    // Before calling functions below, player 1 and player 2 should have completed transfer of their own dice from Dice contract to DiceBattle contract using Dice transfer method
    // hence player 1 and player 2 should be prev owner of their dice after their transfers

    // player 1 and player 2 can call this function to set their enemy, which is each other
    // enemy arg is the account address of other player, not the dice address
    function setBattlePair(address enemy, uint myDice) public {

        // Require that only prev owner can allow an enemy
        // account that is calling function / msg.sender must match dice previous owner
        require(msg.sender == diceContract.getPrevOwner(myDice), "only dice owners can setBattlePair");

        // Each player can only select one enemy
        battle_pair[msg.sender] = enemy;

        // emit selectedBattlePair();
    }

    // After player 1 and player 2 have both set setBattlePair as each other, either of them can call this battle function
    // but they must know both battling dices' diceId, and both battling accounts' addresses to input as arg
    function battle(uint256 myDice, uint256 enemyDice, address myAddress, address enemyAddress) public {
        // Require that battle_pairs align, ie each player has accepted a battle with the other
        require(battle_pair[myAddress] == enemyAddress && battle_pair[enemyAddress] == myAddress, "both players must setBattlePair as each other before they can battle");

        // Run battle
        diceContract.roll(myDice);
        diceContract.roll(enemyDice);
        diceContract.stopRoll(myDice);
        diceContract.stopRoll(enemyDice);

        uint myDiceNumber = diceContract.getDiceNumber(myDice);
        uint enemyDiceNumber = diceContract.getDiceNumber(enemyDice);

        if (myDiceNumber > enemyDiceNumber) {
            diceContract.transfer(enemyDice, myAddress);
            diceContract.transfer(myDice, myAddress);
            addBattleResult(myDice, enemyDice, myAddress, enemyAddress, myAddress, false);
            emit winResult();
        } else if (myDiceNumber < enemyDiceNumber) {
            diceContract.transfer(enemyDice, enemyAddress);
            diceContract.transfer(myDice, enemyAddress);
            addBattleResult(myDice, enemyDice, myAddress, enemyAddress, enemyAddress, false);
            emit loseResult();
        } else { // myDiceNumber == enemyDiceNumber
            diceContract.transfer(enemyDice, enemyAddress);
            diceContract.transfer(myDice, myAddress);
            addBattleResult(myDice, enemyDice, myAddress, enemyAddress, address(0), true);
            emit tieResult();
        }
    }

    //Add relevant getters and setters

    // After Player 1 or 2 have setBattlePair, they can call this method to check their enemy, by providing their own account address as arg
    function getBattlePair(address playerAddress) public view returns(address) {
        return battle_pair[playerAddress];
    }
    // getBattlePair function is actually redundant, as we have made battle_pair variable public as well, just added getBattlePair function for practice purpose
    
    function getWinner(uint256 battleResultId) public view returns (address) {
        return battleResults[battleResultId].winner;
    }

    function getTie(uint256 battleResultId) public view returns (bool) {
        return battleResults[battleResultId].tie;
    }

    function getDiceId1(uint256 battleResultId) public view returns (uint256) {
        return battleResults[battleResultId].diceId1;
    }

    function getDiceId2(uint256 battleResultId) public view returns (uint256) {
        return battleResults[battleResultId].diceId2;
    }

    function getPlayerId1(uint256 battleResultId) public view returns (address) {
        return battleResults[battleResultId].player1;
    }

    function getPlayerId2(uint256 battleResultId) public view returns (address) {
        return battleResults[battleResultId].player2;
    }
}