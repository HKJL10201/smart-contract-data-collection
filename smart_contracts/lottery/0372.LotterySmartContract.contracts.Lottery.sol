// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * * ¿Qué vamos a crear?
 * ! Contrato de loteria inquebrantable
 * *1. Enter the lottery (paying some amount)
 * *2. Pick  a random winner (verificable random)
 * *3. Winner to be selected every X minutes --> completly automated
 *
 * * We are gonna to use CHAINLINK Oracle for the Randomness and automated execution of the smartcontract. The smartconract itself,
 * * has no randomness and need someone to execute the contract everytime.
 */
/**
 * !Orden ideal para contratos de solidity por convencion
 * *Pragma, Imports,Errors, Interfaces, Libraries, NatSPEC antes de -->Contracts
 */
//Imports

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

//errors
error Lottery__notEnough();
error Lottery__TransferFailed();
error Lottery__Closed();
error Lottery__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 numPlayers,
    uint256 LotteryState
);

/**
 * @title A sample of Lottery Contract
 * @author Alejandro Guindo
 * @notice This contract is for creating a untamperable Lottery for pick random winners.
 * @dev This smart contract implements ChainLink VRF v2 and AutomationCompatible
 */
contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /**
     * !Order por convencion para contratos:
     * * Type declarations, state variables, events, modifiers, functions
     */
    //Type Declarations
    //Con esto creamos un tipo de contrato con dos estados. Es igual a decir Uint256 0 = OPEN, 1 = CALCULATING
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    //State Variables

    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUESTCONFIRMATIONS = 3;
    uint32 private constant NUMWORDS = 1;

    uint256 private immutable i_entranceFee;
    address payable[] private s_players;

    //State Variables Lottery

    address private s_recentWinner;
    //Creamos variable de tipo lotteryState llamada s_lotteryState
    LotteryState private s_lotteryState;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    //Events
    /**
     * !Convencion, se pone el nombre inverso de la function donde queremos aplicar el evento
     */
    event RequestedLoterryWinner(uint256 indexed requestId);
    event LotteryEnter(address indexed player);

    event WinnersList(address indexed winner);

    //Modifiers

    constructor(
        address vrfCoordinatorV2, //Contract Address
        uint64 subscriptionId,
        bytes32 keyHash,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_entranceFee = entranceFee;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        //en el constructor, indicamos que variable de nombre s_lotteryState es igual a OPEN concretamente.
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    //Reveice/Fallback

    //Functions que queremos crear
    //------------------------------------------------------------------------------------------------------------------------------
    function enterLottery() public payable {
        // Debemos requerir que msg.value > que i_entranceFee que es el mínimo a pagar

        if (msg.value < i_entranceFee) {
            revert Lottery__notEnough();
        }

        //SOlo queremos que la gente pueda entrar si el estado del contrato es OPEN

        if (s_lotteryState != LotteryState.OPEN) revert Lottery__Closed();

        s_players.push(payable(msg.sender)); //Payable porque se debe poder pagar a estas cuentas luego.

        //EMIT para aplicar el EVENT
        emit LotteryEnter(msg.sender);
    }

    //-----------------------------------------------------------------------------------------------------------------------------
    // Creamos la CheckUpKeep, directamente de chainlink Docu. Esta la necesitamos para comprobar si ha pasado el tiempo
    // que queremos para que la function se ejecute sola.
    /**
     * @dev This is the function that the Chainlink Keeper nodes look for the `upkeepNeeded` to return a boolean true.
     * The following to true, is to find a new random number.
     * Condiciones que queremos apra que se ejecute el random number.
     * 1. Time Interval correcto.
     * 2. El contrato lottery debe tener al menos un jugador y dinero en el contrato
     * 3. La subscription de chainlink automation debe tener LINK suficiente para poder pagarse
     * 4. Teh lottery sohuld be in a "open " state. Cuando esperamos a que se ejecuten la busqueda de random number,
     *  no podemos permitir que alguien se una a la lottery en ese momento, por ello, creamos ENUMS OPEN state para evitar esto.
     * !NOTA: Una vez que upKeepNeeded es TRUE, el nodo offchain the chainlink va a ejecutar directametne PerformUpkeep
     */

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

        return (upkeepNeeded, "0x0");
    }

    //-----------------------------------------------------------------------------------------------------------------------------
    //Dos cosas a completar. Request a random number y una vez que lo tengamos, hacer algo con ello. Por ello para un proceso vamos
    //a tener dos functions. Lo primera solo para el pick random number. La segunda para hacer algo con ello. Es mas seguro asi.
    //Nombres de las functions "copian" los nombres de las functions de VRFConsumerBaseV2.sol de Chainlink
    /**
     * !NOTA. Renamed with performUpkeep, porque es la funcion que el nodo de Chainlink va a buscar para ejecutar.
     * *Antes se llamaba pickRandomWinner
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //Volvemos a validar por seguridad que checkUpKeep es TRUE
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        //En esta function queremos que el estado de la lottery sea CALCULATING, para que nadie pueda entrar
        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestId = i_COORDINATOR.requestRandomWords(
            i_keyHash, //Max gas que vamos a aceptar para realizar el proceso
            i_subscriptionId,
            REQUESTCONFIRMATIONS,
            i_callbackGasLimit,
            NUMWORDS
        );
        emit RequestedLoterryWinner(requestId);
    }

    //Estos parametros los sacamos de copiar el contrato de chainlink. Ademas agregamos en el constructor la address vrfCoordinatorV2
    //para que funcione
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        //una vez tenemos el random number, de ese numero debemos reducirlo para que nos de un numero de 0 a 9 con el que escoger
        //a un random winner.

        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0); //Reseteando el array.

        //Justo despues de encontrar nuestro ganador, volvemos a abrir el estado de la lottry para que gente se pueda unir
        s_lotteryState = LotteryState.OPEN;

        //Reseteamos el timeStamp
        s_lastTimeStamp = block.timestamp;

        //Call
        // Call es el metodo utlizado hoy en dia. devuelve un Boolean
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        //Para más eficiencia de gas
        //require(callSuccess, "Call Failed");
        if (!success) {
            revert Lottery__TransferFailed();
        }

        emit WinnersList(recentWinner);
    }

    //-----------------------------------------------------------------------------------------------------------------------------
    //function automatedExecution() {}

    //-----------------------------------------------------------------------------------------------------------------------------

    //View/Pure Functions
    //Function para hacer publico el i_entraceFee, ya que originalmente la hemos hecho private para ahorrar Gas
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    //Function para hacer pública el address[]players, ya que originalmente la hemos hehco private para ahorrar Gas

    function getAddressPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    //Function para hacer pública el address recentWinner, ya que originalmente la hemos hehco private para ahorrar Gas

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    //Function para hacer pública y ver el LotteryState, ya que originalmente la hemos hehco private para ahorrar Gas

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    //Function para hacer pública y ver el numero de randomWords, ya que originalmente la hemos hehco private para ahorrar Gas

    //PURE para constant variables. Ya que lo lee directamente de las variables.
    function getNumRandomWords() public pure returns (uint256) {
        return NUMWORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    //PURE para constant variables. Ya que lo lee directamente de las variables.
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUESTCONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
