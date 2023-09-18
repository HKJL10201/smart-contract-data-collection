pragma solidity ^0.5.0;

contract Dice {
    
    enum diceState { stationary, rolling }
    
    struct dice {
        uint8 numberOfSides;
        uint8 color;
        uint8 currentNumber;
        diceState state;
        uint256 creationValue;
        address owner;
        address prevOwner;
        uint256 luckyTimes;
    }
    
    event rolling (uint256 diceId);
    event rolled (uint256 diceId, uint8 newNumber);
    event luckytimesEvent(uint256 diceId);
    
    uint256 public numDices = 0;
    mapping(uint256 => dice) public dices;

    //function to create a new dice, and add to 'dices' map. requires at least 0.01ETH to create
    function add(
        uint8 numberOfSides,
        uint8 color
    ) public payable returns(uint256) {
        require(numberOfSides > 0);
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to spawn a new dice");
        
        //new dice object
        dice memory newDice = dice(
            numberOfSides,
            color,
            (uint8)(block.timestamp % numberOfSides) + 1,  //non-secure random number
            diceState.stationary,
            msg.value,
            msg.sender,  //owner
            address(0),
            0 // luckytimes initial
        );
        
        uint256 newDiceId = numDices++;
        dices[newDiceId] = newDice; //commit to state variable
        return newDiceId;   //return new diceId
    }

    //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly(uint256 diceId) {
        require(dices[diceId].owner == msg.sender, "only dice owner can perform this action");
        _;
    }
    
    modifier validDiceId(uint256 diceId) {
        require(diceId < numDices, "only valid dice id can be used");
        _;
    }

    //owner can roll a dice    
    function roll(uint256 diceId) public ownerOnly(diceId) validDiceId(diceId) {
            dices[diceId].state = diceState.rolling;    //set state to rolling
            dices[diceId].currentNumber = 0;    //number will become 0 while rolling
            emit rolling(diceId);   //emit rolling event
    }

    function stopRoll(uint256 diceId) public ownerOnly(diceId) validDiceId(diceId) {
            dices[diceId].state = diceState.stationary; //set state to stationary
            
            //this is not a secure randomization
            uint8 newNumber = (uint8)((block.timestamp*(diceId+1)) % dices[diceId].numberOfSides) + 1;
            dices[diceId].currentNumber = newNumber;

            // check lucky times
            if (newNumber == dices[diceId].numberOfSides) {
                // dices[diceId].luckyTimes++;
                dices[diceId].luckyTimes = dices[diceId].luckyTimes + 1;
                emit luckytimesEvent(diceId);
            }
            emit rolled(diceId, newNumber); //emit rolled
    }
    
    //transfer ownership to new owner
    function transfer(uint256 diceId, address newOwner) public payable ownerOnly(diceId) validDiceId(diceId) {
        dices[diceId].prevOwner = dices[diceId].owner;
        dices[diceId].owner = newOwner;
    }

    //get number of sides of dice    
    function getDiceSides(uint256 diceId) public view validDiceId(diceId) returns (uint8) {
        return dices[diceId].numberOfSides;
    }

    //get current dice number
    function getDiceNumber(uint256 diceId) public view validDiceId(diceId) returns (uint8) {
        return dices[diceId].currentNumber;
    }

    //get ether put in during creation
    function getDiceValue(uint256 diceId) public view validDiceId(diceId) returns (uint256) {
        return dices[diceId].creationValue;
    }

    //get luckyTimes
    function getLuckyTimes(uint256 diceId) public view validDiceId(diceId) returns (uint256) {
        return dices[diceId].luckyTimes;
    }

    //destroy dice
    function destroyDice(uint256 diceId) payable public ownerOnly(diceId) validDiceId(diceId) {
        uint256 value = dices[diceId].creationValue;
        delete dices[diceId]; // Remove from mapping
        msg.sender.transfer(value); // Return value
    }
    
    function getPrevOwner(uint256 diceId) public view validDiceId(diceId) returns (address) {
        return dices[diceId].prevOwner;
    }
}
