pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address payable [] public players;
    // Recomendacion usar tipos mapping para manejar arrays
    // mapping(Key type => Valuetype) public name; 
    // Basicamente es una lista que almacena arrays ([1,0x0001], [1,0x0001]) 
    // https://docs.soliditylang.org/en/v0.8.5/types.html#mapping-types

    // Este es el constructor del contrato en versiones de solidity 5.0 para arriba se define como tal 
    // ya que no se permite que una funcion tenga el mismo nombre que la del contrato y se borra el 
    // keyword function
    constructor() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        //Aqui lo que pasa es que msg.sender es de tipo address, por lo que primero hay que
        //usar un tipo para parsearlo
        players.push(payable(msg.sender));     
    }

    function random() private view returns (uint) {
        //https://ethereum.stackexchange.com/questions/63121/version-compatibility-issues-in-solidity-0-5-0-and-0-4-0/63128
        //esto del abi enconded es por que de la verision 4 a 5 de solidity se rompe la funcion keccak256 y hay que
        //pasarle los argumentos codificados
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    //Asi mismo las funciones que involucran transaccion
    function pickWinner() public payable restricted {
        uint index = random() % players.length;
        //Todos los tipos address que esten involucrados en cualquier tipo de transaccion
        //Necesitan incluir el keyword payable para poder utilizar los metodos de send o transfer
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    //En versiones de solidity >=5.0 es necesario decirle a las funciones de tipo vista
    //que el return solo es utilizado dentro de la ejecucion del contrato con el keyword memory
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}   
