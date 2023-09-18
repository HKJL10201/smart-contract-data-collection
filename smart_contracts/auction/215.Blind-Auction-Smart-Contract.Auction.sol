// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.4.0 <0.7.0; 

contract Auction {
    
    // Oggetto messo all'asta
    struct Object {
        // Id dell'oggetto
        uint id;
        // Descrizione dell'oggetto
        string  description;
    }
    
    address payable public owner;
    uint public ending_time;
    uint public starting_price;
    uint private max_proposal;
    Object public target;
    address private current_winner;
    bool valid;
    
    // Evento per segnalare l'inizio dell'asta
    event Start(address payable owner, string description, uint starting_price, uint ending_time);
    // Evento per segnalare l'esito dell'asta
    event Close(address payable owner, address winner, string description, uint price);
    // Evento per segnalare che l'asta si è conclusa senza vincitori
    event NoWinner(address payable owner, string description);
    
    // Tabella delle proposte
    mapping(address => uint) proposals;
    
    // Costruttore del contratto
    constructor(uint _ending_time, uint _starting_price, string memory description, uint id) public {
        owner = msg.sender;
        ending_time = now +_ending_time;
        starting_price = _starting_price;
        max_proposal = starting_price;
        target = Object(id, description);
        valid = false;
        emit Start(owner, description, starting_price, ending_time);
    }
    
    // Funzione che per fare una proposta
    function propose() payable public {
        require(msg.sender != owner, "Chi ha indetto l'asta non può fare proposte");
        require(now <= ending_time, "Tempo finito");
        /* Verifica se sono già arrivate proposte da quell'indirizzo */ 
        if (proposals[msg.sender] > 0) {
            require(msg.value > proposals[msg.sender], "La tua proposta deve essere maggiore della precedente");
            /* Se aveva già effettuato una proposta ripende gli ether della proposta
            percedente ed effettua la nuova proposta */
            uint money = proposals[msg.sender];
            proposals[msg.sender] = 0;
            msg.sender.transfer(money);
        }
        proposals[msg.sender] = msg.value;
        /* Se arriva una proposta più alta della massima proposta attuale
        si aggiornano proposta massima e l'indirizzo che l'ha effettuata */
        if (msg.value > max_proposal) {
            max_proposal = msg.value;
            current_winner = msg.sender;
            valid = true;
        }
    }
    
    // Funzione per chiudere l'asta
    function close() payable public {
        require(msg.sender == owner, "Solo chi ha indetto l'asta può terminarla");
        require(now > ending_time, "Tempo ancora non terminato");
        /* Se ci sono stata proposte maggiori o uguali al prezzo iniziale, chi ha indetto
        l'asta ritira i soldi di chi ha effettuato la proposta più alta e notifica il
        vincitore dell'asta */
        if (max_proposal >= starting_price && valid == true) {
            uint earn = max_proposal;
            msg.sender.transfer(earn);
            emit Close(owner, current_winner, target.description, max_proposal);
        } else {
            /* Se non sono state effettuate prooste più alte del prezzo di base
            chi ha indetto l'asta segnala che si è conclusa senza vincitori */ 
            emit NoWinner(owner, target.description);
        }
    }
    
    // Funzione per restituire gli ether a chi non ha vinto
    function retake() payable public {
        require(now > ending_time, "Tempo ancora non terminato");
        require(msg.sender != owner, "Chi ha indetto l'asta non può fare ritirare");
        require(msg.sender != current_winner, "Hai vinto l'asta non puoi ritirare");
        require(proposals[msg.sender] != 0, "Non hai messo soldi non puoi ritirare");
        uint money = proposals[msg.sender];
        proposals[msg.sender] = 0;
        msg.sender.transfer(money);
    }
    
}