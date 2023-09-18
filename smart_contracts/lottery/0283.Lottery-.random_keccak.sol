pragma solidity ^0.4.17;

contract LotteryRandomNumber {
    address[] public players;//Array witch players 
    address public manager;

    function Lottery() public {
        manager = msg.sender;//Manager is the deployer of contract
    }

    function playTheLottery() public payable {
        require(msg.value > .01 ether);//minimum amunt to play
        players.push(msg.sender);// player added to array of players
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(block.difficulty, now, players.length));//Cac based on, timestamp, and Array lenght
    }                                                                  

    function Winner() public restricted {
        uint index = getRandomNumber() % players.length;//Calc winner index in array, RandomNumber % Array lenght
        players[index].transfer(this.balance);//Transfer to de winner, the player in this index
        players = new address[](0);//empty the array
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[]) {
        return players;
    }
}