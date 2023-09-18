pragma solidity ^0.4.20;


contract KenoLottery{

    address ceoAddress = msg.sender;
    address cooAddress = msg.sender;
    address cfoAddress = msg.sender;
    address player;
    uint GameValue;
    struct KenoGame{
        address player;
        uint BetValue;
        uint winningValue;
    }
    
    mapping(uint => KenoGame) public kenoGames;
    mapping(address => uint[]) public gameidsOf;
    
    uint public gameid = 0;
     modifier onlyCEO(){
        require(msg.sender == ceoAddress);
            _;
    }

    
    /// @dev Initialization contract
    constructor () public {
    
    ceoAddress = msg.sender;
    }

    /// @dev Create a game
    function playGame(uint value) public payable  returns (uint){
        require(value == msg.value);
        gameid+=1;
        KenoGame storage game = kenoGames[gameid];
        game.player = msg.sender;
        game.BetValue = value;
        game.winningValue = 0;
        gameidsOf[msg.sender].push(gameid);
        return gameid;
    }

    /// @dev Join a game
    function payWinners(uint winningValue, uint gameID) public{
        KenoGame storage game = kenoGames[gameID];
        game.winningValue = winningValue;
        game.player.transfer(game.winningValue);

    }
    
    function withdrawAllFunds() public onlyCEO{
        ceoAddress.transfer(address(this).balance);
    }
    


}