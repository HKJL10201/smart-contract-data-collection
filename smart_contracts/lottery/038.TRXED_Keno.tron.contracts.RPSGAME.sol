pragma solidity ^0.4.20;


contract RpsGame{

    /// @dev Constant definition
    uint8 constant public NONE = 0;
    uint8 constant public ROCK = 10;
    uint8 constant public PAPER = 20;
    uint8 constant public SCISSORS = 30;
    uint8 constant public DEALERWIN = 201;
    uint8 constant public PLAYERWIN = 102;
    uint8 constant public DRAW = 101;

    /// @dev Emited when contract is upgraded
    event CreateGame(uint gameid, address dealer, uint amount);
    event JoinGame(uint gameid, address player, uint amount);
    event Reveal(uint gameid, address player, uint8 choice);
    event CloseGame(uint gameid,address dealer,address player, uint8 result, uint value);


    address ceoAddress = msg.sender;
    address cooAddress = msg.sender;
    address cfoAddress = msg.sender;
    /// @dev struct of a game
    struct Game {
        address dealer;
        uint dealerValue;
        bytes32 dealerHash;
        uint8 dealerChoice;
        address player;
        uint8 playerChoice;
        uint playerValue;
        uint8 result;
        uint gameValue;
        bool closed;
    }

    /// @dev struct of a game
    mapping (uint => mapping(uint => uint8)) public payoff;
    mapping (uint => Game) public games;
    mapping (address => uint[]) public gameidsOf;

    /// @dev Current game maximum id
    uint public maxgame = 0;
    uint public expireTimeLimit = 30 minutes;

    /// @dev Initialization contract
    constructor () public {
        payoff[ROCK][ROCK] = DRAW;
        payoff[ROCK][PAPER] = PLAYERWIN;
        payoff[ROCK][SCISSORS] = DEALERWIN;
        payoff[PAPER][ROCK] = DEALERWIN;
        payoff[PAPER][PAPER] = DRAW;
        payoff[PAPER][SCISSORS] = PLAYERWIN;
        payoff[SCISSORS][ROCK] = PLAYERWIN;
        payoff[SCISSORS][PAPER] = DEALERWIN;
        payoff[SCISSORS][SCISSORS] = DRAW;
        payoff[NONE][NONE] = DRAW;
        payoff[ROCK][NONE] = DEALERWIN;
        payoff[PAPER][NONE] = DEALERWIN;
        payoff[SCISSORS][NONE] = DEALERWIN;
        payoff[NONE][ROCK] = PLAYERWIN;
        payoff[NONE][PAPER] = PLAYERWIN;
        payoff[NONE][SCISSORS] = PLAYERWIN;


    }
    // struct Game {
    //     address dealer;
    //     uint dealerValue;
    //     bytes32 dealerHash;
    //     uint8 dealerChoice;
    //     address player;
    //     uint8 playerChoice;
    //     uint playerValue;
    //     uint8 result;
    //     bool closed;
    // }

    /// @dev Create a game
    function createGame(bytes32 dealerHash, uint value) public payable  returns (uint){
        require(dealerHash != 0x0);
        require(value == msg.value);
        maxgame+=1;
        Game storage game = games[maxgame];

        game.dealer = msg.sender;
        game.dealerValue = value;
        game.dealerHash = dealerHash;
        game.dealerChoice = NONE;
        game.player = 0x0;
        game.playerValue = value;

        gameidsOf[msg.sender].push(maxgame);
        emit CreateGame(maxgame, game.dealer, game.dealerValue);

        return maxgame;

    }

    /// @dev Join a game
    function joinGame(uint gameid, uint8 choice) public payable  returns (uint){
        Game storage game = games[gameid];
        require(msg.value == game.playerValue && game.dealer != address(0) && game.dealer != msg.sender);
        require(game.player == address(0) || game.player == msg.sender);
        require(!game.closed);
        require(checkChoice(choice));
        game.playerValue = msg.value;
        game.player = msg.sender;
        game.playerChoice = choice;
        gameidsOf[msg.sender].push(gameid);
        emit JoinGame(gameid, game.player, game.playerValue);
        return gameid;


    }

    /// @dev Creator reveals game choice
    function reveal(uint gameid, uint8 choice, bytes32 randomSecret) public returns (bool) {
        Game storage game = games[gameid];
        bytes32 proof = getProof(msg.sender, choice, randomSecret );

        require(game.dealerHash == proof);
        require(game.dealerHash != 0x0);
        require(checkChoice(choice));
        require(checkChoice(game.playerChoice));
        require(game.dealer == msg.sender && proof == game.dealerHash);
        game.dealerChoice = choice;
        game.gameValue = game.playerValue + game.dealerValue;
        game.gameValue = game.gameValue * 95 /100;

        emit Reveal(gameid, msg.sender, choice);

        close(gameid);

        return true;


    }

    /// @dev Close game settlement rewards
    function close(uint gameid) public returns(bool) {
        Game storage game = games[gameid];
        require(!game.closed);
        require(game.dealerChoice != NONE && game.playerChoice != NONE);
        uint8 result = payoff[game.dealerChoice][game.playerChoice];

        if(result == DEALERWIN){
            game.dealer.transfer(game.gameValue);
        } else if(result == PLAYERWIN){
            game.player.transfer(game.gameValue);
        }

        game.closed = true;
        game.result = result;

        emit CloseGame(gameid, game.dealer, game.player, result, game.gameValue);

        return true;
    }


    function getProof(address sender, uint8 choice, bytes32 randomSecret) public pure returns (bytes32){
        return keccak256(abi.encode(sender, choice, randomSecret));
    }

    function gameCountOf(address owner) public view returns (uint){
        return gameidsOf[owner].length;
    }

    function checkChoice(uint8 choice) public pure returns (bool){
        return choice==ROCK||choice==PAPER||choice==SCISSORS;
    }
    function createSecretHash(string secret) public pure returns  (bytes32){
        return keccak256(abi.encode(secret));
    }

    function withdrawAllFunds() public{
        ceoAddress.transfer(address(this).balance);
    }

}