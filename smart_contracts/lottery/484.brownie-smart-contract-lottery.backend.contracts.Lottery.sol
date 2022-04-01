// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

//https://docs.chain.link/docs/get-the-latest-price/
//https://docs.chain.link/docs/get-a-random-number/

contract Lottery is Ownable, VRFConsumerBase {
    uint256 public usdTicket;
    address payable[] public players;
    AggregatorV3Interface internal priceFeed;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public state;

    //sacado de la doc de chainlink.
    uint256 public fee;
    bytes32 public keyhash; //forma de identificar univocamente un nodo de chainlink vrf

    uint256 public lastRandom; //esto es simplemente para tener control de estos 2 valores nada mas
    address payable public lastWinner;

    event RequestedRandomness(bytes32 requestId);
    event NewPlayer(address payable player);
    event LotteryHasStarted();
    event CalculatingWinner();
    event LotteryHasEnded(address payable indexed winner, uint256 amount);

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyhash,
        uint256 _ticket_value
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdTicket = _ticket_value * (10**18); //para pasarlo a Wei
        priceFeed = AggregatorV3Interface(_priceFeed); //para poder cambiar de Red
        state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyhash = _keyhash;
    }

    function getPlayersCount() public view returns (uint256) {
        return players.length;
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData(); //fijandome en la doc
        //8 decimales tendria que tener este numero, pero me va a devolver un entero tipo 255665000000 algo asi
        uint256 adjustedPrice = uint256(price) * 10**10;
        //le agregamos 10 lugares al final asi llegamos a 18 en total
        //el tema es llegar a 18 lugares despues del primer digito, asi estamos en la medida de Wei
        //Esto es porque 1 eth = 1000000000000000000 Wei

        uint256 costOfLottery = (usdTicket * 10**18) / adjustedPrice;
        //acordate que el usdticket ya estaba multiplicado por 10**18. Ahora multiplicandolo de vuelta
        //primero nos aseguramos que es mas grande que el denominador, y segundo que nos va a devolver
        //otro numero al cual en el frontend lo tenemos que convertir a 18 decimales, basicamente tendremos
        //que dividir por 10**18. Pero solidity no trabaja con decimales asi que tenemos que hacer esto pasando
        //todo a medida Wei
        return costOfLottery;
    }

    function enterLottery() public payable {
        require(state == LOTTERY_STATE.OPEN, "Lottery is not open!");
        require(msg.value >= getEntranceFee(), "Not enough Eth, you rat!");
        uint256 diff = msg.value - getEntranceFee();
        players.push(msg.sender);

        emit NewPlayer(msg.sender);
    }

    function startLottery() external onlyOwner {
        require(
            state == LOTTERY_STATE.CLOSED,
            "Previous lottery is not finished yet!"
        );
        state = LOTTERY_STATE.OPEN;

        emit LotteryHasStarted();
    }

    function endLottery() external onlyOwner {
        require(state == LOTTERY_STATE.OPEN, "Lottery is already closed");
        state = LOTTERY_STATE.CALCULATING_WINNER;
        //numero random entre 0 y players.length -1 inclusive
        bytes32 requestId = requestRandomness(keyhash, fee);
        //esto va a enviar una transaccion a la blockchain solicitando el random y pagando ese fee.
        //En otra transaccion se me envia el resultado. El nodo de chainlink envia el resultado a VRFCoordinator (rawfulfillRandomness)
        // y este verifica la respuesta y ejecuta la funcion fulfillRandomness. Por eso es internal
        //Basic request model
        emit RequestedRandomness(requestId); //se dispara un evento que queda guardado en la blockchain
        //como un log_info. Ahora este evento queda asociado a la transaccion y puedo accedr a los valores
        //que le pase desde cualquier otro lado, ya sea Frontend o python. Es otra forma de almacenar informacion
        //muchisimo mas barata. Contra? no puedo acceder a esos logs desde el smart contract
        emit CalculatingWinner();
    }

    //siguiendo la documentacion
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        //esta funcion esta solamente declarada en el contrato de VRFCoordinator, justamente para que nosotros
        //escribamos su logica guardando el valor donde queramos.
        require(state == LOTTERY_STATE.CALCULATING_WINNER, "wrong state");
        require(_randomness > 0, "Random not found");
        uint256 indexOfWinner = _randomness % players.length;
        lastRandom = _randomness;
        lastWinner = players[indexOfWinner];
        uint256 amount = address(this).balance;

        lastWinner.transfer(address(this).balance);
        resetLottery();
        emit LotteryHasEnded(lastWinner, amount);
    }

    function resetLottery() internal {
        players = new address payable[](0);
        state = LOTTERY_STATE.CLOSED;
    }
}
