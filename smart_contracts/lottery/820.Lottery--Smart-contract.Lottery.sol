// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Lottery{
    address public manager;  //address which manages lottery
    address payable[] public players; //array of paticipents
    

    constructor()
    {
        manager = msg.sender;
    }
 //function to check whether player is already exists or not
    function alreadyEntered() view private returns(bool)
    {
        for(uint i=0;i<players.length;i++)
        {
            if (players[i]==msg.sender)
            return true;
        }
        return false;
    }
 //function to register player
    function enter() payable public 
    {
        require(msg.sender != manager,"Manager cannot participate"); //checks that manager does not participates
        require(alreadyEntered() == false,"Player already exist"); //checks player is already existed or not
        require(msg.value==1 ether,"Please pay 1 Ether"); //to check only 1 ether is to be send in lottery
        players.push(payable(msg.sender)); //to push player in the array
    }

    //function to get balance
    function getBalance() public view returns(uint)
    {
        require (msg.sender==manager,"Only Manager can access this");
        return address(this).balance;
    }

    //creating function to get players
    function getPlayers() public view returns (address payable[] memory)
    {
        return players;
    }

    //creaing function to generate random number
    function random()private view returns (uint)
    {
        return(uint(sha256(abi.encodePacked(block.difficulty,block.number,players))));
    }

    //creating function to pick winner
    function pickWinner() public returns (address, uint)
    {
        require(msg.sender == manager,"Only Manager can pick winner");
        uint index = random()% players.length; //index of winner
        //address contractAddress = address(this);
        //players[index].transfer(contractAddress.balance);//transfering the amount into winners account
        address payable winner = players[index];
        winner.transfer(getBalance());
        uint Balance= address(winner).balance;
        players = new address payable[](0); // Resseting the lottery
        return (winner,Balance);
    }

}