// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;


//*******Please note that this contract is not optimised and should not be deployed on the main net.**********

contract Lottery{

    address payable[] public players; //players or participant's address will be added in this array which is of payable type
    address manager; //this is the managers address or the address who deploys the this contract
    address payable public winner;// its a winning payable address which will be used to transfer the winning amount to

    //invoked once the contract is deployed to set the manager(address)
    constructor(){
        manager = msg.sender;
    }


    //function to check that particular player already exists in the players array or not
    function noDuplicatePlayers() public view returns(bool){
        for(uint i=0 ; i < players.length; i++){
            if(players[i]== msg.sender){
                return false;
            }
        }
        return true;
    }

    //inbuilt receive function to receive ethers from players to initiate their participation
    receive() external payable{
        require(msg.sender != manager, "Manager cannot be a player");
        require(noDuplicatePlayers()==true, "Player already exists");
        require(msg.value>= 1 ether, "You need to pay atleast 1 ether to continue");
        players.push(payable (msg.sender));
    }

    //to get the balance on the contract after the players send ether for participation
    function getBalance() public view returns(uint){
        require(manager==msg.sender, "You do not have read access as you are no the manager");
        return address(this).balance;
    }

    //function to generate a random number 
    //******** Please note its just a contract deployed on test network. Please do not use this function on your main-net. It isn't secure
    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }

    //function to pickup the winner
    function pickWinner() public{
        require(msg.sender==manager, "You are not the manager");
        require(players.length>=3, "Players are less than 3");

        uint rand = random();
        uint index = rand  % players.length;
        winner = players[index];
        winner.transfer(getBalance());
        players = new address payable[](0); //once the winner has been selected we will reset the players array 
    }

    //function to get the addresses of all the participating players
    function allPlayers() public view returns(address payable[] memory){
        return players;
    }
    }

