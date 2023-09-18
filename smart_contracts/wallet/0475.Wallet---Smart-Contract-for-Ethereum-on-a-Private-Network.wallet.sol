pragma solidity ^0.4.18;

contract mortal{
    address owner;
    
    function mortal() public {  // construtor do contrato
        owner = msg.sender;
    }
    
    modifier onlyowner{ // para evitar escrever sempre esta condição em várias funções
        if(owner == msg.sender){
            _;
        }else{
            revert();//pára a ação e devolve os fundos envolvidos ao owner do contrato
        }
    }
    
    function kill() public onlyowner{  // funço kill que destroi o contrato
        selfdestruct(owner);
    }
    
}

contract wallet is mortal{  //contrato wallet herda funções do contrato mortal
    
    mapping(address => Permission) permittedAddresses; // mapa(parecido ao hashmap do JAVA) em que as entradas são os adresses e as suas chaves são a struct Permission
    
    struct Permission{
         bool isAllowed;
        uint maxTransferAmount;   // valor máximo que um endereço autorizado pode fazer no total de todas as suas transações
        
    }
    
    // evento que é despoletado quando é adicionado um endereço ao mapa de endereços autorizados a fazer transações
    event someoneAddedSomeoneToTheSenderList(address thePersonWhoAdded, address thePersonWhoIsAllowedNow, uint thisMUchMeCanSend);
    
    function addAddressToSenderList(address permitted, uint maxTransferAmount) public onlyowner{ // função em que apenas o owner do contrato pode adicionar endereços
        permittedAddresses[permitted] = Permission(true,maxTransferAmount);
        someoneAddedSomeoneToTheSenderList(msg.sender,permitted,maxTransferAmount);
    }
    
    function sendFunds(address receiver, uint amountInWei)public{ // verifica se um endereço está autorizado e tem fundos suficientes
        if(permittedAddresses[msg.sender].isAllowed){
            if(permittedAddresses[msg.sender].maxTransferAmount >= amountInWei){ 
                bool isAmountSent = receiver.send(amountInWei);
                if(!isAmountSent){
                    revert();               // senão tiver fundos suficientes ou se ocorrer algum erro o rpocesso é revertido e quaisquer fundos voltam para o contrato
                }
            }
        
        }else{
            revert();
        }
    }
    
    function removeAddressToSenderList(address theAddress)public onlyowner{ // apenas o owner pode remover endereços da lista
        delete permittedAddresses[theAddress];
    }
    
    function () payable public{ // função que permite transferir ether para o contrato
        
    }
    
}

