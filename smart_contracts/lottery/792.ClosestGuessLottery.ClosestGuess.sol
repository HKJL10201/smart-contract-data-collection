pragma solidity ^0.5.11;

contract Game {
    struct Player {
        address _address;
        uint256 _secret;
        uint256 _bet;
        uint256 _guess;
        bool _isRevealCorrect;
        uint256 _correctGuesses;
    }
    
    struct Winning { // holds both winners and loosers in case of failure
        address _address;
        uint256 _bet;
    }
    
    Player[] _players;
    Winning[] public _winners;
    Winning[] public _loosers;//these are the players who did not reveal therir guesses correctly
    uint256 _totalBet = 0;
    bool _isActive;
    uint256 _guessAccumulator = 0;
    uint256 _maxPlayers = 0;
    uint256 _revealedPlayers = 0;
    
    constructor(uint256 maxPlayers) public {
        _maxPlayers = maxPlayers;
        _isActive = true;
    }
    
    modifier onlyWhenActive() {
        require(_isActive, "Game is inactive");
        _;
    }
    
    function numberOfPlayers() onlyWhenActive public view returns (uint256 numPlayers) {
        return _players.length;
    }
    
    function getTotalBet() onlyWhenActive public view returns (uint256 totalBet) {
        return _totalBet;
    }
    
    function hammingWeight(uint256 x) internal pure returns (uint256) {
        uint256 w = 0;
        while (x!=0){
            w += x&1;
            x >>= 1;
        }
        return w;
    }
    
    function updateWinners() internal {
        uint256 winningNumber = uint256(sha256(abi.encode(_guessAccumulator)));
        uint256 mx = 0;
        for (uint256 i=0; i<_players.length; i++) {
            _players[i]._correctGuesses = hammingWeight(winningNumber ^ _players[i]._guess ^ 
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            if (_players[i]._correctGuesses > mx) mx = _players[i]._correctGuesses;
        }
        for (uint256 i=0; i<_players.length; i++) {
            if(_players[i]._correctGuesses == mx) {
                Winning memory winner = Winning({_address: _players[i]._address, _bet: _players[i]._bet});
                _winners.push(winner);
            }
        }
    }
    
    function numberOfWinners() public returns (uint256) {
        return _winners.length;
    }
    
    function getWinner(uint256 i) public returns (address addr, uint256 bet) {
        return (_winners[i]._address, _winners[i]._bet);
    }
    
    function updateLoosers() internal {
        for (uint256 i=0; i<_players.length; i++) {
            if (!_players[i]._isRevealCorrect) {
                Winning memory looser = Winning({_address: _players[i]._address, _bet: _players[i]._bet});
                _loosers.push(looser);
            }
        }
    }
    
    function closeGame() onlyWhenActive public returns (bool isEverybodyRevealed) {
        _isActive = false;
        if (_revealedPlayers == _players.length){
            updateWinners();
            return true;
        }
        else{
            updateLoosers();
            return false;
        }
    }
    
    function betToGame(address addr, uint256 secret, uint256 bet) onlyWhenActive public {
        require(_players.length < _maxPlayers, "Maximum number of players reached, you can not bet");
        Player memory p = Player({_address: addr, _secret: secret, _bet: bet, 
                               _guess: 0, _isRevealCorrect: false, _correctGuesses: 0});
        _players.push(p);
        _totalBet += bet;
    }
    
    function revealGuess(address addr, uint256 guess) onlyWhenActive public {
        for(uint i=0; i<_players.length; i++) {
            if(_players[i]._address == addr){
                uint256 x = uint256(addr) ^ guess;
                uint256 h = uint256(sha256(abi.encode(bytes32(x))));
                require(h == _players[i]._secret, "Your revealed guess is incorrect");
                _players[i]._guess = guess;
                _guessAccumulator ^= guess;
                _revealedPlayers += 1;
                return;
            }
        }
        require(false, "You did not bet in the game");
    }
}

contract ClosestGuess {
    address _owner;
    uint256 _minBet = 1 ether;
    uint256 _maxPlayers = 1000;
    uint256 _betEndTime;
    uint256 _revealEndTime;
    bool _gameOpen = false;
    Game _game;
    address _lotteryOwnerAddress;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "access denied");
        _;
    }
    
    modifier notOwner() {
        require(msg.sender != _owner, "access denied");
        _;
    }
    
    constructor() public {
        _owner = msg.sender;
        _lotteryOwnerAddress = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    }
    
    function createGame(uint minBet, uint maxPlayers) onlyOwner public {
        require(minBet>0, "Minimum bet must be positive");
        require(maxPlayers>1, "More than 1 player should be able to play");
        require(!_gameOpen, "A game is already open");
        _gameOpen = true;
        _minBet = minBet;
        _maxPlayers = maxPlayers;
        _betEndTime = now + 30 seconds;
        _revealEndTime = _betEndTime + 10 seconds;
        _game = new Game(_maxPlayers);
    }
    
    function getGameInfo() public view returns (uint256 minBet, uint256 maxPlayers, 
            uint256 betEndTime, uint256 revealEndTime, uint256 numPlayers, uint256 totalBet) {
        require(_gameOpen, "There is no active game");
        return (_minBet, _maxPlayers, _betEndTime, _revealEndTime, 
                _game.numberOfPlayers(), _game.getTotalBet());
    }
    
    function closeGameWithSuccess() internal {
        uint256 numOfWinners = _game.numberOfWinners();
        address[] memory winnerAddresses;
        uint256 totalShares = 0;
        for (uint256 i=0; i<numOfWinners; i++){
            uint256 t;
            address a;
            (a, t) = _game.getWinner(i);
            totalShares += t;
            winnerAddresses[i] = a;//push did not work
        }
    }
    
    function closeGameWithFailure() internal {
        
    }
    
    function closeGame() public {
        require(_gameOpen, "There is no active game");
        require(now > _revealEndTime, "Game is in process, connot close now");
        _gameOpen = false;
        _minBet = 0;
        _maxPlayers = 0;
        _betEndTime = 0;
        _revealEndTime = 0;
        bool success = _game.closeGame();
        if (success) closeGameWithSuccess();
        else closeGameWithFailure();
        delete _game;
    }
    
    function () payable external {
        require(false, "You cannot pay to this account directly");
    }
    
    function betToActiveGame(uint256 secret) public notOwner payable {
        require(now < _betEndTime, "Betting stage of the game is closed");
        require(_game.numberOfPlayers()<_maxPlayers, "Total player count for the game is reached");
        uint256 bet = msg.value;
        require(bet>=_minBet, "Insufficient bet amount");
        address adr = msg.sender;
        _game.betToGame(adr, secret, bet);
    }
    
    function revealGuessForActiveGame(uint256 guess) public notOwner {
        require(now > _betEndTime, "Bet stage of the game is in process, you shouldn't reveal your guess");
        require(now < _revealEndTime, "Revealing stage of the game is closed");
        address adr = msg.sender;
        _game.revealGuess(adr, guess);
    }
}
