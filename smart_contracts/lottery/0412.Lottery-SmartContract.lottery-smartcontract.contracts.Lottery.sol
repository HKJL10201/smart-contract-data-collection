pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() public {
        manager=msg.sender; //assign the deployment address to variable manager
    }

    function enter() public payable {  //can't enter lottery for free so payable
        require(msg.value > 0.01 ether);  //converts to wei
        players.push(msg.sender);  //add player to array
    }


    function random() private view returns(uint){
        //sha3();  //global so we can use it without import
       return uint( keccak256(block.difficulty, now, players)); //instance of sha3 so can use also sha3()
       //, other variables are global. Now refers to time.
    }

    function pickWinner() public restricted{

        uint index = random() % players.length;

       players[index].transfer(address(this).balance);
       //lastWinner = players[index];
        players=new address[](0); //start lottery again after money has been paid out
    }

    function getCurrentBalance() public view returns(uint) {
        return (address(this).balance);
    }

    modifier restricted(){ //for re-use
        require(msg.sender == manager);
        _; // compiler will take all the code from function with restricted and
        // assign it to _;

    }

    function getPlayers() public view returns(address[]){
        return players;
    }

}
