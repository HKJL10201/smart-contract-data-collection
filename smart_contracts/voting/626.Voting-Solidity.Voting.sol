// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

//Smart Contract para crear un sistema de votación.
contract Voting {
    //Mapping para comprobar las direcciones de los votantes
    mapping(address=>bool) public voters;
    //Estructura de la elección.
    struct Choice {
        uint id;
        string name;
        uint votes;
    }
    //Estructura de la campaña de votación.
    struct Ballot{
        uint id;
        string name;
        Choice[] choices;
        uint end;
    }
    //Mapping de las elecciones.
    mapping(uint => Ballot) ballots;
    //Variable para proxima votación.
    uint nextBallotId;
    //Dirección del admin del sistema de votación.
    address public admin;
    //Mapping para comprobar si ya se ha votado.
    mapping(address => mapping(uint => bool))votes;

    //Constructor el admin debe ser el que crea el smart contract.
    constructor(){
        admin = msg.sender;
    }

    //Función para añadir votantes (solo lo puede hacer el admin).
    function addVoters(address[] calldata _voters) external onlyAdmin(){
        //Loop para añadir los votantes.
        for(uint i = 0; i<_voters.length ;i++){
            //Definir los votantes y pasar el boleano a true.
            voters[_voters[i]]=true;
        }
    }

    //Función para crear la campaña de votación.
    function createBallot(string memory name, string [] memory choices, uint offset )public onlyAdmin(){
        //Definir variable de id
        ballots[nextBallotId].id= nextBallotId;
        //Definir variable del nombre de la campaña de votación
        ballots[nextBallotId].name= name;
        //Definir la variable del tiempo que dura la campaña
        ballots[nextBallotId].end = block.timestamp + offset;
        //Loop para añadir la campaña de votación.
        for(uint i = 0; i<choices.length; i ++){
            ballots[nextBallotId].choices.push(Choice(i, choices[i],0));
        }
    }

    //Crear un modifier para que solo el admin pueda añadir votantes y crear campañas.
    modifier onlyAdmin(){
        require(msg.sender == admin, "Solo el Admin");
        _;
    }
    //Función de votar
    function vote(uint ballotId, uint choiceId)external{
        //Require de que solo los votantes pueden votar
        require(voters[msg.sender]==true, "Solo los voters pueden votar");
        //Require de que solo se puede votar una vez.
        require(votes[msg.sender][ballotId] == false, "Solo se puede votar una vez");
        //Require que solo se puede votar antes de finalizar la campaña.
        require(block.timestamp < ballots[ballotId].end, "votar antes de finalizar");
        //Cambiar el bolleano de los votos a true.
        votes[msg.sender][ballotId] = true;
        //Añadir los votos a la campaña de votación.
        ballots[ballotId].choices[choiceId].votes++;
    }

    //Función para comprobar los votos de la campaña.
    function results( uint ballotId) view external returns(Choice[]memory){
        //Require solo se puede comprobar una vez finalizada la campaña.
        require(block.timestamp> ballots[ballotId].end, "No se puede ver los resultados antes de finalizar");
        //Retornar la elección de la campaña elegida.
        return ballots[ballotId].choices;
    }
}