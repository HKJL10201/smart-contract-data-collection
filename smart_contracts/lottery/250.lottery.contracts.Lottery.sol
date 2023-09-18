pragma solidity ^0.4.17;

contract Lottery {
    //quem envia o contrato
    address public manager;
    //lista de contratos
    address[] public players;
//o contrutor Lottery atribui o endereco do criador do contrato msg.sender a variavel manager
 
    function Lottery() public {
        manager = msg.sender;
    }
//funcao para entrar no sorteio, pegando o endereco da pessoa(manager) e passando para sender
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public restricted {
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
//view nao faz nenhuma mudanca no contrato
//getPlayers acessa o array do jogador 
    function getPlayers() public view returns (address[]) {
        return players;
    }
}   