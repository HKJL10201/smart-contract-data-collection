pragma solidity ^0.4.24;

interface IBlockDice {
    function startRoll (bytes32 hash, uint8 verifyBlocks) external returns(uint256 finishBlock);
    function finishRoll (bytes32 key, uint8 sides, uint8 count) external 
        returns(uint8[] memory roll);
    function abortRoll () external;
    function getRoll (bytes32 key, uint8 sides, uint8 count) external view
        returns(uint8[] memory roll);
}

contract BlockDice65Turn3 {
    
    struct Turn {
        uint8 verifyBlocks;
        uint8 rolls;
        uint8 count;
        uint8[] bank;
    }

    address private _owner;//remove in production

    IBlockDice private _dice;

    mapping(address => Turn) private _turn;
    
    event TurnStarted (
        address indexed account,
        uint8 verifyBlocks,
        uint256 timestamp
    );
    
    event TurnContinued (
        address indexed account,
        uint8[] bank,
        uint256 timestamp
    );
    
    event TurnEnded (
        address indexed account,
        uint8[] bank,
        uint256 timestamp
    );

    constructor(address diceAddress) public { 
        _owner = msg.sender;//remove in production
        _dice = IBlockDice (diceAddress);
    }
    
    function startTurn (bytes32 hash, uint8 verifyBlocks) external {
        require (_turn[tx.origin].rolls == 0, "Already in a turn"); 
        require (verifyBlocks != 0, "verifyBlocks must be > 0");

        _dice.startRoll(hash, verifyBlocks);//reverts on 0x0 hash
        
        _turn[tx.origin] = Turn (verifyBlocks, 1, 0, new uint8[](6));

        emit TurnStarted (
            tx.origin,
            verifyBlocks,
            now
        );
    }
    
    function continueTurn (
        bytes32 turnKey, bytes32 nextHash, uint8[] bankFilter
    ) external returns(uint8[] memory bank, bool turnComplete) {
        require (bankFilter.length == 6, "Invalid bankFilter"); 
        require (_turn[tx.origin].rolls != 0, "Not in a turn"); 

        uint8[] memory roll = _dice.finishRoll(turnKey, 6, 5-_turn[tx.origin].count);
        bank = _turn[tx.origin].bank;
        uint8 diceCount = 0;
        uint8 index = 0;
        if (roll.length > 0) {
            for (index = 0; index < roll.length; index++) bank[roll[index]] += 1;
            if (_turn[tx.origin].rolls < 3 && nextHash != 0x0) {
                for (index = 0; index < 6; index++) {
                    if (bankFilter[index] < bank[index]) bank[index] = bankFilter[index];
                    diceCount += bank[index];
                }
            } else diceCount = 5;
        } else {//expired, zeroed penalty
            for (index = 0; index < 6; index++) {
                if (bank[index] != 0) bank[index] = 0;
            }
        }  

        if (diceCount < 5) {
            turnComplete = false;
            _dice.startRoll(nextHash, _turn[tx.origin].verifyBlocks);
            _turn[tx.origin].rolls += 1;
            _turn[tx.origin].count = diceCount;
            _turn[tx.origin].bank = bank; 
            emit TurnContinued (
                tx.origin,
                bank,
                now
            );
        } else {
            turnComplete = true;
            delete _turn[tx.origin];
            emit TurnEnded (
                tx.origin,
                bank,
                now
            );
        }

    }

    function getBank (bytes32 turnKey) external view returns(uint8[] memory bank) {
        require (_turn[tx.origin].rolls != 0, "Not in a turn"); 

        uint8[] memory roll = _dice.getRoll(turnKey, 6, 5-_turn[tx.origin].count);
        bank = _turn[tx.origin].bank;
        uint8 index = 0;
        if (roll.length > 0) {
            for (index = 0; index < roll.length; index++) bank[roll[index]] += 1;
        } else {//expired, zeroed penalty
            for (index = 0; index < 6; index++) if (bank[index] != 0) bank[index] = 0;
        }  
    }

    function getRoll (bytes32 turnKey) external view returns(uint8[] memory roll) {
        require (_turn[tx.origin].rolls != 0, "Not in a turn"); 
        roll = _dice.getRoll(turnKey, 6, 5-_turn[tx.origin].count);
    }

    function abortTurn () external returns(bool turnComplete) {
        if (_turn[tx.origin].rolls != 0) {
            _dice.abortRoll();
            emit TurnEnded (
                tx.origin,
                _turn[tx.origin].bank,
                now
            );
            delete _turn[tx.origin];
            turnComplete = true;
        }
    }
    
    function turnComplete() external view returns (bool isComplete) {
        isComplete = (_turn[tx.origin].rolls == 0);
    }

    //remove in production
    function destroy() external {
       require (msg.sender == _owner);
       selfdestruct(_owner);
    }
    
    //Return to sender, any abstract transfers
    function () external payable { msg.sender.transfer(msg.value); }

}