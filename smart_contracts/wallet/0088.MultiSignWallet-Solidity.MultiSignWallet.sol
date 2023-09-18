// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;


contract MultiSignWallet {
    //Direccioens de los validadores
    address [] public approvers;
    //Numero de validadores para ponerse de acuerdo
    uint public quorum;
    //Estructura de una transferencia
    struct Transfer{
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }
    //Mapping de las transferencias
    mapping(uint => Transfer)transfers;
    //Incremento del Id de las transferencias
    uint nextId;
    //Mapping de las approvaciones de los validadores
    mapping(address=> mapping(uint =>bool))approvals;

    //Constructor de nuestro smart contract.
    constructor(address[] memory _approvers, uint _quorum) payable {
        approvers = _approvers;
        quorum = _quorum;
    }

    //Funcion de crear las transferencias
    function createTransfer(uint amount, address payable to)external onlyApprover() {
        //Creamos nuestra transferencia.
        transfers[nextId] = Transfer(nextId,amount,to,0,false);
        //Incrementamos los ids.
        nextId++;
    }

    //Funcion de enviar dinero
    function sendTransfer(uint id)external payable onlyApprover(){
        //Creamos un require para ver que la transaccion no ha sido ya enviada
        require(transfers[id].sent ==false, 'La transaccion se ha enviado');
        //Si no hay aprobaciones, incrementarlas y cambiar a estado true.
        if(approvals[msg.sender][id]==false){
        //Cambiamos el estado de las aprobaciones a true    
        approvals[msg.sender][id]=true;
        //Incrementamos los approvals.
        transfers[id].approvals++;
        }
        //Si las aprovaciones ya son iguales al quorum o superiores enviar la transferencia.
        if(transfers[id].approvals >= quorum){
            //Cambiamos el booleano del sent a true 
            transfers[id].sent = true;
            //Definimos direccion para enviar transferencia
            address payable to = transfers[id].to;
            //Definimos la cantidad de dinero
            uint amount = transfers[id].amount;
            //Enviamos la cantidad de la  transferencia.
            to.transfer(amount);
            return;
        }
    }

    //Creacion de un modificador.
    modifier onlyApprover(){
        bool allowed = false;
        for(uint i= 0; i <approvers.length;i++){
           if(approvers[i]==msg.sender){
               allowed = true;
           }
        }
        require(allowed==true, 'Solo estan permitidos validadores');
        _;
    }
}
