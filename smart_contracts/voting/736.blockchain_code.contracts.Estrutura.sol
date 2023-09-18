pragma solidity ^0.5.0;

/**
 * The contractName contract does this and that...
 */
contract Pauta {
  
  // O morador vai sempre receber x tokens em cada reuniao, porém ele pode decedir 
  //usar mais tokens para um item do que para outro token: caso ele queria aquele item ganhe d+;
	struct Morador {
		//uint token;  //Segunda fase
		bool voted;
		uint8 vote;
	}

	struct Item {
	    bytes32 titulo;
		uint qtdSim;
		uint qtdNao;
	}
	
	address sindico;
	Item[] itens;
	mapping (address => Morador) moradores;
	
  constructor(uint8 _quantidadeItem) public {
     sindico = msg.sender
     moradores[sindico].token = _quantidadeItem;
     itens.length = _quantidadeItem;
  }

  function dandoAcessoMorador(address _morador) public returns (bool) {
  	require (msg.sender == sindico, "Você não é o Sindico desta votação!!!");
  	moradores[_morador];	
  }
  
  function enviandoItens (bytes32[] _pautas) public returns(bool) {
  	
  	require (_pautas.length == itens.length, "O numero de pautas está diferente do iniciado por favor verifique novamente!!!");
  	for(uint i =0; i< _pautas.length; i++){
  		itens.push(Item({
  			titulo: _pautas[i],
  			qtdVotos: 0;	
  			}));
  	}
  	
  }

  function votar(bool[] _voto, uint[] item) public returns (bytes32) {
  	Morador storage sender = moradores[msg.sender];
  	require (sender == msg.sender, "Vc não tem permissão de votar!!!");
  	require (!sender.voted, "Vc já votou em todos os itens!!!");
  	require (item.length == itens.length, "Quantidade de itens insuficientes");
  	
  	for(uint i =0; i < item.length; i++){
  		if(!_voto[i]){
  			itens[i].qtdNao +=1;
  			continue;
  		}
  		itens[i].qtdSim += 1;
  	}

  	moradores[msg.sender].voted = false;
  	return  keccak256(block.timestamp, msg.sender);
  }
  


  function resultadoVotacao (uint _item) public view returns(uint _qtdSim, uint _qtdNao) {
  	itens[_item]._qtdSim;
  	itens[_item]._qtdNao;
  }
  

  


}

