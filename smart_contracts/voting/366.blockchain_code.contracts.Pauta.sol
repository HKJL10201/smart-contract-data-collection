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
  
    Item itemPauta;
  address sindico;
  mapping (address => Morador) moradores;

  modifier onlySindico() {
     require (msg.sender == sindico, "Você não é o Sindico desta votação!!!");
         _;
    }
  
  constructor(bytes32 _item) public {
     sindico = msg.sender;
     moradores[sindico];
     itemPauta = Item(_item, 0, 0);
  }

  function dandoAcessoMorador(address _morador) onlySindico public view returns (bool) {
    moradores[_morador];  
  }
  

  function votar(bool _voto, uint item) public returns (bytes32) {
    //require (!moradores[msg.sender], "Vc não tem permissão de votar!!!");
    require (!moradores[msg.sender].voted, "Vc já votou em todos os itens!!!");
    
    if(_voto){
      itemPauta.qtdSim += 1;
    }else{
      itemPauta.qtdNao += 1;
    }   

    moradores[msg.sender].voted = false;
    return keccak256(abi.encodePacked(block.timestamp, msg.sender, _voto, item));
     
  }
  
  function resultadoItem() public view returns(uint, uint) {
    itemPauta.qtdSim;
    itemPauta.qtdNao;
  }
  
  

}

