pragma solidity ^0.4.24;

interface IBlockDice65Turn3 {
    function startTurn (bytes32 hash, uint8 verifyBlocks) external;
    function continueTurn (bytes32 turnKey, bytes32 nextHash, uint8[] bankFilter) external 
        returns(uint8[] memory bank, bool turnComplete);
    function abortTurn () external returns(bool turnComplete);
    function turnComplete() external view returns (bool isComplete);
    function getBank (bytes32 turnKey) external view returns(uint8[] memory bank);
    function getRoll (bytes32 turnKey) external view returns(uint8[] memory roll);
}

contract DiceGameYatzy {

    struct Game {
        address account;
        uint16 score;
        uint8 verify;
        uint8 turns;
        uint8[] tally;
    }

    struct Account {
        uint256 game;
        uint256 total;
        uint256 score;
    }
    
    address private _owner;//remove in production
    
    IBlockDice65Turn3 private _dice;
    
    uint256 private _gameIndex;
    mapping(uint256 => Game) private _game;
    mapping(address => Account) private _account; 
    
    event GameStarted (
        address indexed account,
        uint256 indexed gameId,
        uint8 verify,
        uint256 timestamp
    );
    
    event GameContinued (
        address indexed account,
        uint256 indexed gameId,
        uint8[] tally,
        uint16 score,
        uint8 turn,
        uint256 timestamp
    );
    
    event GameEnded (
        address indexed account,
        uint256 indexed gameId,
        uint8[] tally,
        uint16 score,
        uint256 timestamp
    );
    
    constructor(address diceAddress) public { 
        _owner = msg.sender;//remove in production
        _gameIndex = 0;
        _dice = IBlockDice65Turn3 (diceAddress);
    }
    
    function startGame (
        bytes32 hash, uint8 verifyBlocks
    ) external returns(uint256 gameId) {
        require (_account[msg.sender].game == 0, "Already in a game"); 
        require (verifyBlocks != 0, "verifyBlocks must be > 0");
        
        _dice.startTurn(hash, verifyBlocks);
        
        gameId = ++_gameIndex;
        if (_account[msg.sender].total == 0) {
            _account[msg.sender] = Account (gameId, 0, 0);
        } else _account[msg.sender].game = gameId;

        _game[gameId] = Game (msg.sender, 0, verifyBlocks, 0, new uint8[](15));

        emit GameStarted (
            msg.sender,
            gameId,
            verifyBlocks,
            now
        );
    }

    function continueGame (
        bytes32 turnKey, bytes32 nextHash, uint8[] bankFilter, uint8 cat
    ) external returns(bool completed) {
        require (_account[msg.sender].game != 0, "Not in a game"); 
        uint256 gameId = _account[msg.sender].game;
        require (cat < 15 && _game[gameId].tally[cat] == 0, 
            "Category already scored");
        
        (
        uint8[] memory bank,
        bool turnComplete
        ) = _dice.continueTurn(turnKey, nextHash, bankFilter);

        if (turnComplete) {
            uint8 catScore = scoreCategory(cat, bank);//255 == 0
            if (catScore != 0) {
                _game[gameId].tally[cat] = catScore;
                _game[gameId].score += catScore;
            } else _game[gameId].tally[cat] = 255;
            _game[gameId].turns += 1;
            if (_game[gameId].turns < 15) {//continue game
                _dice.startTurn(nextHash, _game[gameId].verify);
                emit GameContinued (
                    msg.sender,
                    gameId,
                    _game[gameId].tally,
                    _game[gameId].score,
                    _game[gameId].turns,
                    now
                );
            } else {//end game
                if (_game[gameId].score > 0 && 
                    _account[msg.sender].total + 1 > _account[msg.sender].total &&
                    _account[msg.sender].score + _game[gameId].score > _account[msg.sender].score
                ) {
                    _account[msg.sender].total += 1;
                    _account[msg.sender].score += _game[gameId].score;
                }
                _account[msg.sender].game = 0;
                emit GameEnded (
                    msg.sender,
                    gameId,
                    _game[gameId].tally,
                    _game[gameId].score,
                    now
                );

                completed = true;
            }
        }
    }

    function abortGame () external returns(bool completed) {
        if (_account[msg.sender].game != 0) {
            uint256 gameId = _account[msg.sender].game;
            _dice.abortTurn();
            if (_game[gameId].score > 0 && 
                _account[msg.sender].total + 1 > _account[msg.sender].total &&
                _account[msg.sender].score + _game[gameId].score > _account[msg.sender].score
            ) {
                _account[msg.sender].total += 1;
                _account[msg.sender].score += _game[gameId].score;
            }
            _account[msg.sender].game = 0;
            emit GameEnded (
                msg.sender,
                gameId,
                _game[gameId].tally,
                _game[gameId].score,
                now
            );

            completed = true;
        }
    }

    function deleteGame(uint256 gameId) external {
        require (_game[gameId].account == msg.sender, 'Invalid Game');
        delete _game[gameId];
    }

    //remove in production
    function destroy() external {
       require (msg.sender == _owner);
       selfdestruct(_owner);
    }
    
    //Return to sender, any abstract transfers
    function () external payable { msg.sender.transfer(msg.value); }

    function getTurnBank (bytes32 turnKey) external view returns(uint8[] memory bank) {
        require (_account[msg.sender].game != 0, "Not in a game"); 
        bank = _dice.getBank(turnKey);
    }

    function getTurnRoll (bytes32 turnKey) external view returns(uint8[] memory roll) {
        require (_account[msg.sender].game != 0, "Not in a game"); 
        roll = _dice.getRoll(turnKey);
    }

    function getGame(uint256 gameId) external view returns (
        address account,
        uint16 score,
        uint8 verify,
        uint8 turns,
        uint8[] memory tally
    ) {
        account = _game[gameId].account;
        score = _game[gameId].score;
        verify = _game[gameId].verify;
        turns = _game[gameId].turns;
        tally = _game[gameId].tally;
    }

    function getAccount(address account) external view 
        returns (uint256 gameId, uint256 total, uint256 score) {
        gameId = _account[account].game;
        total = _account[account].total;
        score = _account[account].score;
    }

    function gameScore(uint256 gameId) external view returns (uint16 score) {
        score = _game[gameId].score;
    }

    function verifyActiveGame(address account, uint256 gameId) external view 
        returns (bool verified) {
        verified = (account != address(0) && gameId != 0 && 
            _account[account].game == gameId);
    }
    
    function scoreCategory(uint8 category, uint8[] memory bank) internal pure 
        returns (uint8 score) {
        score = (
            (category == 0) ? bank[0] ://1s
            (category == 1) ? bank[1] * 2 ://2s
            (category == 2) ? bank[2] * 3 ://3s
            (category == 3) ? bank[3] * 4 ://4s
            (category == 4) ? bank[4] * 5 ://5s
            (category == 5) ? bank[5] * 6 ://6s
            (category == 6) ? (//highest pair
                (bank[5] > 1) ? 12 : (bank[4] > 1) ? 10 : (bank[3] > 1) ? 8 :
                (bank[2] > 1) ? 6 : (bank[1] > 1) ? 4 : (bank[0] > 1) ? 2 : 0) :
            (category == 7) ? (//2 pair
                (bank[5] > 1 && bank[4] > 1) ? 22 :
                (bank[5] > 1 && bank[3] > 1) ? 20 :
                ((bank[5] > 1 && bank[2] > 1) || (bank[4] > 1 && bank[3] > 1)) ? 18 :
                ((bank[5] > 1 && bank[1] > 1) || (bank[4] > 1 && bank[2] > 1)) ? 16 :
                ((bank[5] > 1 && bank[0] > 1) || (bank[4] > 1 && bank[1] > 1) 
                    || (bank[3] > 1 && bank[2] > 1)) ? 14 :
                ((bank[4] > 1 && bank[0] > 1) || (bank[3] > 1 && bank[1] > 1)) ? 12 :
                ((bank[3] > 1 && bank[0] > 1) || (bank[2] > 1 && bank[1] > 1)) ? 10 :
                (bank[2] > 1 && bank[0] > 1) ? 8 :
                (bank[1] > 1 && bank[0] > 1) ? 6 : 0) :
            (category == 8) ? (//triple
                (bank[5] > 2) ? 18 : (bank[4] > 2) ? 15 : (bank[3] > 2) ? 12 :
                (bank[2] > 2) ? 9 : (bank[1] > 2) ? 6 : (bank[0] > 2) ? 3 : 0) :
            (category == 9) ? (//quad
                (bank[5] > 3) ? 24 : (bank[4] > 3) ? 20 : (bank[3] > 3) ? 16 :
                (bank[2] > 3) ? 12 : (bank[1] > 3) ? 8 : (bank[0] > 3) ? 4 : 0) :
            (category == 10) ? (//low straight
                (bank[4] == 1 && bank[3] == 1 && bank[2] == 1 && 
                    bank[1] == 1 && bank[0] == 1) ? 15 : 0) :
            (category == 11) ? (//high straight
                (bank[5] == 1 && bank[4] == 1 && bank[3] == 1 && 
                    bank[2] == 1 && bank[1] == 1) ? 20 : 0) :
            (category == 12) ? (//full house
                (bank[5] == 3) ? (
                    (bank[4] == 2) ? 28 : (bank[3] == 2) ? 26 : (bank[2] == 2) ? 24 :
                    (bank[1] == 2) ? 22 : (bank[0] == 2) ? 20 : 0) :
                (bank[4] == 3) ? (
                    (bank[5] == 2) ? 27 : (bank[3] == 2) ? 23 : (bank[2] == 2) ? 21 :
                    (bank[1] == 2) ? 19 : (bank[0] == 2) ? 17 : 0) :
                (bank[3] == 3) ? (
                    (bank[5] == 2) ? 24 : (bank[4] == 2) ? 22 : (bank[2] == 2) ? 18 :
                    (bank[1] == 2) ? 16 : (bank[0] == 2) ? 14 : 0) :
                (bank[2] == 3) ? (
                    (bank[5] == 2) ? 21 : (bank[4] == 2) ? 19 : (bank[3] == 2) ? 17 :
                    (bank[1] == 2) ? 13 : (bank[0] == 2) ? 11 : 0) :
                (bank[1] == 3) ? (
                    (bank[5] == 2) ? 18 : (bank[4] == 2) ? 16 : (bank[3] == 2) ? 14 :
                    (bank[2] == 2) ? 12 : (bank[0] == 2) ? 8 : 0) :
                (bank[0] == 3) ? (
                    (bank[5] == 2) ? 15 :  (bank[4] == 2) ? 13 : (bank[3] == 2) ? 11 :
                    (bank[2] == 2) ? 9 : (bank[1] == 2) ? 7 : 0) : 0) :
            (category == 13) ? (//yatzy
                (bank[5] == 5 || bank[4] == 5 || bank[3] == 5 || bank[2] == 5 || 
                    bank[1] == 5 || bank[0] == 5) ? 50 : 0) :
            (category == 14) ? (//chance
                (bank[5] * 6) + (bank[4] * 5) + (bank[3] * 4) + (bank[2] * 3) + 
                    (bank[1] * 2) + (bank[0] * 1)) : 0
        );
    }

}