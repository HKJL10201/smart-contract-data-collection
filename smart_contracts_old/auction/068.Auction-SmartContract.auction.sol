// Version de solidity del Smart Contract
pragma solidity >=0.4.22 <0.7.0;

// Informacion del Smart Contract
// Nombre: Subasta
// Logica: Implementa subasta de productos entre varios participantes

// Declaracion del Smart Contract - Auction
contract Auction {

    // ----------- Variables (datos) -----------
    // Información de la subasta
    string public description;
    uint public basePrice;
    uint256 private secondsToEnd;
    uint256 public createdTime;

    // Antiguo/nuevo dueño de subasta
    address payable public originalOwner;
    address public newOwner;

    // Puja mas alta
    address payable public highestBidder;
    uint public highestPrice;
    
    // Estado de la subasta
    bool public activeContract;
    
    // ----------- Eventos (pueden ser emitidos por el Smart Contract) -----------
    event Status(string _message);
    event Result(string _message, address winner);

    // ----------- Constructor -----------
    // Uso: Inicializa el Smart Contract - Auction con: description, precio y tiempo
    constructor() public {
        
        // Inicializo el valor a las variables (datos)
        description = "En esta subasta se ofrece un coche. Se trata de un Ford Focus de ...";
        basePrice = 1 ether;    
        secondsToEnd = 86400;
        activeContract = true;
        createdTime = block.timestamp;
        originalOwner = msg.sender;
        
        // Se emite un Evento
        emit Status("Subasta creada");
    }
    
    // ------------ Funciones que modifican datos (set) ------------

    // Funcion
    // Nombre: bid
    // Uso:    Permite a cualquier postor hacer una oferta de dinero para la subata
    //         El dinero es almacenado en el contrato, junto con el nombre del postor
    //         El postor cuya oferta ha sido superada recibe de vuelta el dinero pujado
    function bid() public payable {
        if(block.timestamp > (createdTime + secondsToEnd)  && activeContract == true){
            checkIfAuctionEnded();
        } else {
            if (msg.value > highestPrice && msg.value > basePrice){
                // Devuelve el dinero al ANTIGUO maximo postor
                highestBidder.transfer(highestPrice);
                
                // Actualiza el nombre y precio al NUEVO maximo postor
                highestBidder = msg.sender;
                highestPrice = msg.value;
                
                // Se emite un evento
                emit Status("Nueva puja mas alta, el ultimo postor tiene su dinero de vuelta");
            } else {
                // Se emite un evento
                emit Status("La puja no es posible, no es lo suficientemente alta");
                revert();
            }
        }
    }

    // Funcion
    // Nombre: checkIfAuctionEnded
    // Uso:    Comprueba si la puja ha terminado, y en ese caso, 
    //         transfiere el balance del contrato al propietario de la subasta 
    function checkIfAuctionEnded() public{
        if (block.timestamp > (createdTime + secondsToEnd)){
            // Finaliza la subasta
            activeContract = false;
            
            // Transfiere el dinero (maxima puja) al propietario original de la subasta
            newOwner = highestBidder;
            originalOwner.transfer(highestPrice);
            
            // Se emiten varios eventos
            emit Status("La subasta ha finalizado");
            emit Result("El ganador de la subasta ha sido:", highestBidder);
        } else {
            revert();
        }
    }
        
    // ------------ Funciones de panico/emergencia ------------

    // Funcion
    // Nombre: stopAuction
    // Uso:    Para la subasta y devuelve el dinero al maximo postor
    function stopAuction() public{
        require(msg.sender == originalOwner);
        // Finaliza la subasta
        activeContract = false;
        // Devuelve el dinero al maximo postor
        highestBidder.transfer(highestPrice);
        
        // Se emite un evento
        emit Status("La subasta se ha parado");
    }
    
    // ------------ Funciones que consultan datos (get) ------------

    // Funcion
    // Nombre: getAuctionInfo
    // Logica: Consulta la description, y la fecha de creacion de la subasta
    function getAuctionInfo() public view returns (string memory, uint){
        return (description, createdTime);
    }
    
    // Funcion
    // Nombre: getHighestPrice
    // Logica: Consulta el precio de la maxima puja
    function getHighestPrice() public view returns (uint){
        return (highestPrice);
    }
    
}
