pragma solidity ^0.4.17;

contract Lottery{
    address public manager;
    address[] public players;
    address public contestWinner;
    function Lottery()public{
        manager = msg.sender; //Getting the address of the manager
    }

    function enter()public payable{
        //Vy default the value will be taken in wei, to change it we need to specify it as below
        require(msg.value >.01 ether);//Its a function used for validation, if bool passed to the function returns to false then the entire function will fail
        players.push(msg.sender);
    }

    function randomNumGenerator() private view returns(uint){
        //First we will create a random no generator
        //Block Diificulty,Current Time,Player Addresses ->SHA Algortihm->Really big no->This no will be used to pick a random winner
        return uint(keccak256(block.difficulty,now,players));
    }

    // function pickWinner() public restricted{ //Enable this to allow only managers to pick winner
        function pickWinner() public{
        //Make sure only manager can call this
        // require(msg.sender == manager);//Only person that originally created the contract(manager) will be able to create this
        var randnum = randomNumGenerator();
        var winner =  players[randnum%players.length];

        //this.balance will give us the balance/amt of money remaining in the current contract
        winner.transfer(this.balance);
        contestWinner = winner;
        //Once contract execution is complete, we reset the contract
        players = new address[](0); //Creating a new dynamic array of type address 
    }

    modifier restricted(){

	// <Code that you want to duplicate/acccess from multiple methods>
	 require(msg.sender==manager);
	_;
}
    function getPlayers()public view returns(address[]){
        return players;
    }
   
}