pragma solidity 0.5.2;

contract Ownable {
  address payable public owner;
  event OwnerShipTransferred(address newOwner);
 
 address sindico;
 event SindicoTransfirdo(address newSindico);
 
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() { 
    require (msg.sender == owner, "Vc não é o dono"); 
    _; 
   }
   
   modifier onlySindico(){
        require (msg.sender == sindico, "Vc não é o sindico"); 
    _; 
   }

  function transferOwnerShip (address payable newOwner) onlyOwner public {
      owner = newOwner;

      emit OwnerShipTransferred(owner);
  }
  
  function SindicoTransferido (address newSindico) onlyOwner public {
      sindico = newSindico;

      emit SindicoTransfirdo(sindico);
  }

}

contract Pauta {
   
    
    function cadastrarItem(string memory _pauta) public returns (bool); 

    event Cadastrada(address indexed _from, string _pauta);
}

contract PautaBasic is Ownable, Pauta{
    
    struct Item{
        string titulo;
        uint32 votosAFavor;
        uint32 votosContra;
    }

    uint total;
    Item[] public itens; 
    
    function cadastrarItem(string memory _pauta) onlySindico public returns (bool){
        itens.push(Item(_pauta, 0,0));
        total = total + 1;
        emit Cadastrada(msg.sender, _pauta);
        return true;
    }
}

contract Assembleia is PautaBasic{
    
    struct Morador{
        bool presente;
    }
    
    mapping(address => Morador) moradores;
    
    function acessoMorador(address _morador, bool _apto) onlySindico public returns (bool){
        moradores[_morador] = Morador(_apto);
        return true;
    }
  
}

contract Votacao is Assembleia {
    event ResultadoFinal(string _pautaVotada, uint32 _sim, uint32 _nao);
    event IniciarVotacao();
    event EncerrarVotacao();
    
    function realizarVoto(uint32 _item, bool _voto) public returns (bytes32){
        //require(!moradores[msg.sender].presente, "Vc não tem permissão de voto nesta Assembleia");
        
        if(!_voto){
            itens[_item].votosContra += 1; 
        }else{
            itens[_item].votosAFavor += 1; 
        }
        
        return keccak256(abi.encodePacked(block.timestamp, msg.sender, _item, _voto));
    }
    
    function resultadoItem(uint32 _codigoItem) public {
  
        emit ResultadoFinal(
            itens[_codigoItem].titulo, 
            itens[_codigoItem].votosAFavor,
            itens[_codigoItem].votosContra);

    } 
}

