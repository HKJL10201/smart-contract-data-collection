//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "hardhat/console.sol";

/*
Deployed at 0x2FA70990b49cb4d689201Bafb205DDfE12f57B49
https://rinkeby.etherscan.io/address/0x2FA70990b49cb4d689201Bafb205DDfE12f57B49
*/
contract LotteryGame {
    struct Game {
        uint256 id;
        address[] players;
        uint256 price;
        uint256 total;
        address winner;
        bool hasWinner;
        uint256 endDate;
    }

    uint256 private currentId;
    mapping(uint256 => Game) private games;
    mapping(uint256 => mapping(address => bool)) private uniquePlayers;
    address private owner;

    constructor() {
        owner = msg.sender;
        currentId = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function createGame(uint256 _price, uint256 _seconds) payable public onlyOwner {
        require(_price > 0, "Ticket price must be greater than zero");
        require(_seconds > 0, "Game time must be greater than zero");
        Game memory newGame = Game({
            id: currentId,
            players: new address[](0),
            total: 0,
            price: _price,
            winner: address(0),
            hasWinner: false,
            endDate: block.timestamp + _seconds * 1 seconds
        });

        games[currentId] = newGame;
        currentId++;
    }

    function takePart(uint256 _gameId) public payable {
        Game storage game = games[_gameId];
        require(block.timestamp < game.endDate, "Game is already complete");
        require(game.price == msg.value, "Value must be equal to ticket price");
        
        game.players.push(msg.sender);
        game.total += msg.value;
        bool alreadyTakePart = uniquePlayers[_gameId][msg.sender];
        // Player can only take part 1 time
        if (alreadyTakePart == false) {
            uniquePlayers[_gameId][msg.sender] = true;
        }
    }

    function pickWinner(uint256 _gameId) public onlyOwner {
        Game storage game = games[_gameId];
        require(block.timestamp < game.endDate, "Game is already complete");
        require(!game.hasWinner, "Game has already a winner");
        if (game.players.length == 1) {
            require(game.players[0] != address(0), "There are no players in this game");
            game.winner = game.players[0];
            game.hasWinner = true;
            (bool success, ) = game.winner.call{value: game.total}("");
            require(success, "Transfer failed");
        } else {
            uint256 winner = random(game.players) % game.players.length;
            game.winner = game.players[winner];
            game.hasWinner = true;
            (bool success, ) = game.winner.call{value: game.total }("");
            require(success, "Transfer failed");
        }
    }

    function random(address[] memory _players) public view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _players)));
    }

    function getGame(uint256 _gameId) public view returns (Game memory) {
        return games[_gameId];
    }

    function getGamesCount() public view returns(uint256) {
        return currentId;
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
}