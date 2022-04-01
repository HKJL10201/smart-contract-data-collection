pragma solidity ^0.7.0;


contract Portefeuille{
    
    address public admin;
    
    constructor(){
        admin=msg.sender;
    }
    
    // doit envoyer et recevoir les ether
    // il doit nous montrer la balance de chaque compte ou adresse
    // il doit nous montrer la balance total du contract en ether
    //structure pour l'usisateur
    // l'autorisation, on doit autoriser aux utilisateurs de faire les operations
    
    struct Details {
        uint identification;
        uint blanceUtilisateur;
        uint timestamp;
    }
    
    mapping(address=>Details)public details;
    event Receipt(address indexed _beneficiaire, uint _montant);
    event Transfer(address indexed _expeditaire,address indexed _beneficiaire,uint _montant);
    modifier seulAdmin(){
        require(msg.sender==admin,"tu n'as pas le droit de retirer");
        _;
    }
    
    modifier seulMontantautorise(uint _montant){
         require(details[msg.sender].blanceUtilisateur>=_montant,"tu n'as pas de fond suffisant pour faire la transaction");
        _;
    }
    
    receive() external payable{
        details[msg.sender].blanceUtilisateur += msg.value;
        details[msg.sender].timestamp=block.timestamp;
        details[msg.sender].identification++;
        emit Receipt(msg.sender,msg.value);
    }
    
    
    function balanceTotal()view public returns(uint){
        return address(this).balance/1 ether;
    }
    
     function retirerBlance()public seulAdmin{
         
         msg.sender.transfer(address(this).balance);
     }
    
    function retrait(address payable _beneficiaire, uint _montant)public seulMontantautorise(_montant) {
       
        details[msg.sender].blanceUtilisateur -=_montant;
        details[_beneficiaire].blanceUtilisateur+=_montant;
        details[_beneficiaire].timestamp=block.timestamp;
        _beneficiaire.transfer(_montant);
        details[_beneficiaire].identification++;
        emit Transfer(msg.sender,_beneficiaire,_montant);
    }
    
    
    
    
    
}