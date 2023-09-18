
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;



contract Lottery{
    // as one of the player in the array will be winner 
    // and will recive all the funds that's we declare it as 
    // payable
    // with playable - we can send ether to it
    address payable[] public players;
    string public name;

    // the lotter will also have a manager which is externally owned the 
    // account that deployes the contract, start the lottery, picks the winne and resets
    //it for the next round
     address public manager;

     constructor(){
         name = "Lottery Dapp Project";
         manager= msg.sender;
         // challenge - 2
           // adding the manager to the lottery
       //  players.push(payable(manager));
     }

   
    event AmountReceive(
        uint price
    );
   
   // how someone can enter in the lottery

   // - a user enters the lottery simply by using a wallet to send 0.1 eth
   // to the contract address, the user address will be dynamically added to player array
   // and the sent amount will be added to contract balance

  // declaring recieve function for the contract to receive ether

  // this function cant have arguments cant return anything also must have external visibilty
     receive() external payable{

         // challenge 1 
         // the manager can not participate in the lottery
        //require(msg.sender != manager);

        // every user will send 0.1 eth - if user wants more chances to winthen they do more 
        // trasaction

       //  require(msg.value==100000000000000000); instead of this
         require(msg.value==1 ether,'a player must send 1 ether'); // if there is any piece of code before require that will consume gas

        // here we add address that sends eth to the contract in the player's array
        players.push(payable(msg.sender)); // now anyone how sends eth will be added to the players array
        
        emit AmountReceive(1 ether);

     } 

    // method to return contracts balance in wei
    function getBalance() public view returns(uint){
        require(msg.sender==manager,'only manager can access it');
        return address(this).balance;
    }


    // how to select winner of the lottery
    // after entering into the lottery the manager can randomly selects the winner

  
    function RandomGenerator() public view returns(uint){
         
         // this will take a single argument of type bytes 
         // this argument is a func that perform packed encoding of the given arguments
         // and return a variable of type bytes
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length))); // this method will compute the hash of the input using
        //keccak256 has algorithm


        // Chainlink VRF use for random number generation in solidity

    }


    // method to picks the winner and transfer the entire eth amount to the winner
    function pickWinner() public{
   //challenge -3
        // anyone can pick the winner if there are at least 10 players in the lottery
        // require(msg.sender == manager);  // anyone can pick the winner
       // require (players.length >= 10);


        require(msg.sender==manager);
        require(players.length>=3);
        uint r = RandomGenerator();
        address payable winner;
        uint index= r % players.length;
        winner= players[index];
        winner.transfer(getBalance());


      // challenge -4  - manager can receive 10% of lottery fund
        // uint managerFee = (getBalance() * 10 ) / 100; // manager fee is 10%
        // uint winnerPrize = (getBalance() * 90 ) / 100;     // winner prize is 90%
        
        // transferring 90% of contract's balance to the winner
       // winner.transfer(winnerPrize);
        
        // transferring 10% of contract's balance to the manager
      //  payable(manager).transfer(managerFee);



    // reset the lottery to be ready for the next round
    // we simply do that by resetting the players dynamic array
    // 0 means the size of new dynamic array
      players = new address payable[](0);

          }






}