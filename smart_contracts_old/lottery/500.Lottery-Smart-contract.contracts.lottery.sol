pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    //variable of type address for the manager( the person who ceates the contract)

    address[] public players;
     //variable of type address and a dynamic array of multiple players who enter the lottery

    function Lottery() public {
        manager = msg.sender;
        //no declaration needed for msg variable
    }

    function enter() public payable {
        //This function uses the type payable because ether will be sent along with it

        require(msg.value > .01 ether);
        //this ensures that the lowest amount of ether any player can send is 0.01 ether

        players.push(msg.sender);
        //This adds the transaction sender's address to a list of entrants for the lottery
    }

    function random() private view returns (uint) {
        //this function is private and doesn't modify the contract hence view and also returns an unsigned integer
       return uint(keccak256(block.difficulty, now, players));
       //this returns a unsigned integer that takes in the keccak256 algorithm with the block difficulty, time and address of players 
    }

    function pickWinner() public restricted {
        uint index = random() % players.length;
        //This results in an index of the players array signifying the winner of the lottery

        players[index].transfer(this.balance);
        //methods can be called on address types in solidity and players[index] signifies the address of the winner
        //players[index].transfer makes it possible to send wei to the winner of the lottery
        //this.balance signifies the total amount of money within the contract

        players = new address[](0);
        //we the reset the list of players to nill after picking the winner so we dont have to deploy the contract after picking a winner
        //so we assign the player variable to a new address type that is a dynamic array and also has a length or size of 0
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
        //This function reduces the amount of redundancy with our code by substituting the particular function that requires manager verification
        //into the underscore
    }

    function getPlayers() public view returns (address[]) {
        return players;
        //this returns a list of all the players who have entered the lottery
    }

}