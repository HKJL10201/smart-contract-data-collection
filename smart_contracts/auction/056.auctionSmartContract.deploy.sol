// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//on créer un contrat déployable par un autre contrat
contract A{
    address public ownerA;

//Externally owned adress(eoa) sera le msg.sender du compte qui appelle la fonction
    constructor(address eoa){
        ownerA = eoa;
    }


}

contract Creator{
    address public ownerCreator;
    //on sauvegarde les éléments de type adress de l'instance de A dans un array dynamique
    A[] public deployedA;

//le createur de l'enchère prend la valeur du msg.sender
    constructor(){
    ownerCreator = msg.sender;
    }

    function deployA()public {
        //nouvelle instance du contrat A appelé par le compte externe 
        A new_A_adress = new A(msg.sender);
        //on push la nouvelle adress dans l'array
        deployedA.push(new_A_adress);
    }
}