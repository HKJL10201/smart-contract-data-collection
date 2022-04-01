pragma solidity >=0.4.22 <0.6.0;

import "./Pauta.sol";

contract Votacao {
    
    Pauta[]  pautas;
    address sindico;
    uint32[]  resultadoSim ;
    uint32[]  resultadoNao ;
        
    event iniciarVotacao(
            uint _duracao,
            uint _timeAtual,
            address _iniciador,
            address[] _listaMoradores
        );
    event encerradaVotacao(
            uint _timeFinal,
            address _finalizador,
            uint32[] _sim,
            uint32[] _nao
        );
    
    event novaVotacaoCriada(
            address _from,
            bytes32 txHash,
            uint _time
        );
        
    modifier onlySindico(){
        require(sindico == msg.sender, "Apenas o Sindico pode iniciar uma votação");
        _;
    }
  
    function criarNovaVotacao(uint[] memory _itens) public {
        //require(msg.value == 0.001 ether, "É necessario 0.001 ether para começar o processo de votação!!!");
        require(5 == _itens.length, "Apenas é permitido ter 5 pautas por votação!!!");
    	sindico = msg.sender;
    	for(uint32 i =0; i< _itens.length; i++){
    	    	pautas.push(new Pauta(_itens[i]));
    	}
    	emit novaVotacaoCriada(msg.sender, 
    	    keccak256(abi.encode(msg.sender, _itens, block.timestamp)), 
    	block.timestamp);
    }
    
    function iniciar(uint _duracao, address[] memory _moradores) onlySindico public {
        for(uint32 j =0; j< pautas.length; j++){
            for(uint32 l=0; l < _moradores.length; l++){
                pautas[j].dandoAcessoMorador(_moradores[l]);
            }
        }
        emit iniciarVotacao(
                _duracao,
                block.timestamp,
                msg.sender,
                _moradores
            );
    }
    
    function finalizar() onlySindico public {
        for(uint32 k= 0; k< pautas.length; k++){
         (uint32 sim, uint32 nao) = pautas[k].resultadoItem();
         resultadoSim.push(sim);
         resultadoNao.push(nao);
        }
    emit encerradaVotacao(
                block.timestamp,
                msg.sender,
               resultadoSim,
               resultadoNao
            );  
    }

    function votar(bool[] memory itensPautas) public returns (bytes32){
        require(5 == itensPautas.length, "Quantidade de Itens Acima do permitido para esta votação ");
        for(uint32 j =0; j< pautas.length; j++){
    	  Pauta p = pautas[j];
    	  p.vote(itensPautas[j]);
        }
        keccak256(abi.encodePacked(msg.sender, itensPautas, block.timestamp));
    }
    
    function verificarPauta(uint who) public returns(uint,uint,uint){
        Pauta p = pautas[who];
        p.itemPauta;
    }
 
}


