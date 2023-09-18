/ SPDX-License-Identifier: GPL-3.0
//Wallet di pubblicazione 0xCb6Cfef287146795Ea8dd836B3A3a8688514BB1c
//0x15c2e6a9a1bb84817e0654d11fbeef109c1f9559  contratto pubblicato 0,001702


pragma solidity ^0.8.17;

/**
*Smart Contrat for the manage of Lottery 
*/

contract Clavus_Lottery {

    address public owner;      // variabile che detiene l'owner dello SMart Contract
    address payable[] public players; //Array dei giocatori

    constructor () {
        owner = msg.sender;     //Indirizzo che ha fatto il deploy del contratto
     }
     
     //Funzione che restituisce i fondi dello smart contract
     function GetBalance () public view returns(uint){
         return address(this).balance;
     }
    
     function GetPlayers () public view returns (address payable[] memory) {
                
                return players;
     }
 //Funziona che esplicita quanti sono i players in gioco
     function GetNumberPlayers () public view returns(uint){
         require (msg.sender == owner);
         return players.length;
     }

      //Funzione che trasferisce all'OWNER del contratto i fondi rimanenti
     function GetBalanceToOwner () public OnlyOwner{
         require (msg.sender == owner);
        // address.transfer (address(this).balance);
         payable(owner).transfer (address(this).balance);
     }

     
      //Funzione che salva in players l'elenco degli address di chi ha depositato fondi
     function enter() public payable {
           //verifica che sia stato pagato almeno 0.1 ether
           require (msg.value >= 0.1 ether );
            //inserisce in Players l'indizzo di chi ha mandato fondi allo MSart Contract
           players.push(payable(msg.sender)); 
    }
    function GetRandomNumber () public view returns(uint){
        return uint (keccak256(abi.encodePacked(owner,block.timestamp)));
    }
    function PickWinner ()public OnlyOwner{
        //dimezzo i fondi disponibili sullo smart contract
        uint vincita = address(this).balance / 2;
        uint index = GetRandomNumber () % players.length;
        players[index].transfer (vincita);
        //resettiamo l'array dei partecipanti
        players= new address payable[](0);
    }

    modifier OnlyOwner() {
        require (msg.sender == owner);
        _;

    }
}