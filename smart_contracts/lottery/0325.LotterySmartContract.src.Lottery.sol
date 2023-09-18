pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

import "./src/ERC20Basic";

contract Lottery {

    ERC20Basic private token;
    address public owner;
    address public contractAddress;
    uint public createdTokens = 10000;

    constructor() public {
        owner = msg.sender;
        token = new ERC20Basic(createdTokens);
        contractAddress = address(this);
    }

    //  evento de compra de token
    event buyingToken(uint, address);

    //  establecer precio de token en ether, calcula el coste del token en ether
    function tokenPriceToEther(uint tokenNumber) internal pure returns (uint) {
        return tokenNumber * (1 ether);
    }

    //  generar mas token por loteria
    function generateMoreToken(uint tokenNumber) public onlyExecute(msg.sender) {
        token.increaseTotalSupply(tokenNumber);
    }

    //  modificador para controlar funciones ejecutablespor Disney
    modifier onlyExecute(address addressOwner) {
        require(addressOwner == owner, "Permission denied, dont have permission for execute");
        _;
    }

    //  comprar tokens
    function buyTokens(uint tokenNumber) public payable {
        //  se calcula el coste del token
        uint cost = tokenPriceToEther(tokenNumber);
        require(msg.value >= cost, "Dont have enogh money to buy tokens");
        //  transferencia de la diferencia a pagar
        msg.sender.transfer(msg.value - cost);
        //  obtener balance de token del contrato
        uint balance = tokenAvailable();
        //  filtro para evaluar token a comprar
        require(tokenNumber <= balance, "Buy less quantity of tokens");
        //  transferencia de token al comprador
        token.transfer(msg.sender, tokenNumber);
        emit buyingToken(tokenNumber, msg.sender);
    }

    //  cantidad de tokens habilitados
    function tokenAvailable() public view returns (uint){
        return token.balanceOf(contractAddress);
    }

    //  obtener balance de token acumulados para el ganador
    function visualizeTokenQuantityForWinner() public view returns (uint) {
        return token.balanceOf(owner);
    }

    //  balance de token de una persona
    function myTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    //  precio del boleto en token
    uint public tokenPrice = 5;
    //  relacion entre persona que compra boleto y numero de los boletos
    mapping(address => uint[]) personTicketMapping;
    //  relacion para identificar al ganador
    mapping(uint => address) adnTicketMapping;
    //  random number
    uint randomNonce = 0;
    //  boletos generados
    uint[] ticketBought;

    event buyingTicket(uint, address);
    event winnerTicket(uint);
    event tokenReturns(uint, address);

    //  funcion para comprar boletos
    function buyTickets(uint ticketNumber) public {
        //  precio total de los boletos
        uint totalPrice = ticketNumber * tokenPrice;
        //  filtro de token a pagar
        require(totalPrice <= myTokens(), "Need to buy more tokens");
        //  transferencia de token al owner -> premio
        token.transferLottery(msg.sender, owner, totalPrice);
        //  se genera un numero aleatorio tomando la marca de tiempo actual, msg.sender y nonce, se utiliza keccak256
        //  para generar un hash aleatorio, y se castea a un uint, y se divide por 10k para obtener los ultimos 4 digitos
        for (uint i = 0; i < ticketNumber; i++) {
            uint randomNumber = uint(keccak256(abi.encodePacked(now, msg.sender, randomNonce))) % 10000;
            randomNonce ++;
            //  almacenando datos de los boletos
            personTicketMapping[msg.sender].push(randomNumber);
            ticketBought.push(randomNumber);
            //  asignar adn del boleto para obtener ganador
            adnTicketMapping[randomNumber] = msg.sender;
            emit buyingTicket(randomNumber, msg.sender);
        }
    }

    //  visualizar numero de voletos de una persona
    function myTickets() public view returns (uint[] memory) {
        return personTicketMapping[msg.sender];
    }

    //  funcion para generar un ganador e ingresarle los token
    function generateWinner() public onlyExecute(msg.sender) {
        //  debe haber mas de un voleto comprado
        require(ticketBought.length > 0, "There is not tickets bought");
        //  declaracion de la longitud del array
        uint length = ticketBought.length;
        //  aleatoriamente elijo numero entre 0 y longitud
        uint iArray = uint(keccak256(abi.encodePacked(now))) % length;
        //  seleccion del numero aleatorio mediante la posicion del array
        emit winnerTicket(ticketBought[iArray]);
        //  recuperar la direccion del ganador y transferir
        token.transferLottery(msg.sender, adnTicketMapping[ticketBought[iArray]], visualizeTokenQuantityForWinner());
    }

    //  devolucion de token a eth
    function returnTokens(uint tokenNumber) public payable {
        //  numero de token a devolver debe ser mayor a cer
        require(tokenNumber < 0, "Need to return a positive number of tokens");
        //  usuario debe tener los token que desea devolver
        require(tokenNumber <= myTokens(), "Not have enough token to return");
        //  cliente devuelve los tokens
        token.transferLottery(msg.sender, address(this), tokenNumber);
        msg.sender.transfer(tokenPriceToEther(tokenNumber));
        emit tokenReturns(tokenNumber, msg.sender);
    }
}
