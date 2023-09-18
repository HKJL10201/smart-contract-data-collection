// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
// prendo il contratto che mi da il valore eth/usd
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// prendo il contratto che mi permette di chiamare end e start lottery
import "@openzeppelin/contracts/access/Ownable.sol";
// prendo il contratto che mi permette di generare un numero random
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase, Ownable {
    // un array di payable addresses che contiene i giocatori della lotteria
    address payable[] public players;
    uint256 public usdEntryFee;
    uint256 public randomness;
    // variabile dove caricare il contratto dell'orcale chainlink
    AggregatorV3Interface internal ethUsdPriceFeed;
    // definisco gli stati della lotteria, anche se li scrivo a lettere è come se stessi scrivendo stato 0,1,2
    enum LOTTERY_STATE {
        OPEN,
        CLOSE,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    bytes32 keyHash;
    uint256 fee;
    address  payable public recentWinner;
    event RequestedRandomness(bytes32 requestId);
    event PlayersArray(address payable[] players);
    event CatchPlayerEntering(address playerAddress);

    // posso aggiungere i costruttori dei contratti dai quali inerito, qui gli do i valore del contratto VRF che mi prende il numero, il contratto link al quale pagare la fee, la fee e l'identificativo del contratto vrf sottoforma di keyhash
    constructor(
        address _priceFeedAddress,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        usdEntryFee = 50 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        // quando deployo il contratto la lotteria è chiusa
        lottery_state = LOTTERY_STATE.CLOSE;
        fee = _fee;
        keyHash = _keyHash;
        emit PlayersArray(players);
    }

    // la funzione per entrare nella lotteria
    function enter() public payable {
        // controllo che la lotteria sia aperta
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "La lotteria non è aperta"
        );
        // controllo che il giocatore paghi una somma superiore o uguale a quella richiesta per giocare(TODO)
        require(
            msg.value >= getEntranceFee(),
            "paaaaaghhhaaaaa, sgancia, spilla, sborsa, investi, compra, assolda proprio"
        );
        // carico l'address del giocatore nell'array dei giocatori
        emit CatchPlayerEntering(msg.sender);
        players.push(msg.sender);
    }

    //la funzione che determina il valore min di entrata grazie all'oracle chainlink
    function getEntranceFee() public view returns (uint256) {
        // prendo quanto è il valore in dollari di 1 ether
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        // qui non fo * 18 ma *10 perchè dal contratto torna di suo un numero da 8 decimali
        uint256 adjustedPrice = uint256(price) * 10**10;
        // qui rimoltiplico per 10 alla 18 perche senno mi viene fuori un numero con la virgola
        // ma dato che è int non posso usarlo quindi lo rimoltiplico per 10 alla 18 cosi da renderlo un int e in formato wei
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    //solo l'autore può far partire o chiudere la lotteria
    function startLottery() public onlyOwner {
        // non avvio la lotteria se non è chiusa in primo luogo
        require(
            lottery_state == LOTTERY_STATE.CLOSE,
            "La lotteria è gia aperta/sta calcolando il vincitore"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        // questa funzione ritorna bytes32 requestId
        bytes32 requestId = requestRandomness(keyHash, fee);
        // usiamo questo evento per fingerci un nodo chainlink
        emit RequestedRandomness(requestId);
    }

    // la rendo internal cosi solo il vrf può chaiamre questa funzione, ovverride è un opzione che sovrascrive il contenuto della funzione nel contratto d'appartenenza
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "Non è ancora stato deciso il vincitore"
        );
        require(
            _randomness > 0,
            "il vrf è ubriaco e non ha ancora dato indietro il numero random"
        );
        // con questa operazione il modulo tornerà sempre un indice possibile per i posti dell'array players
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        // trasferisco i big money dei poveri bastardi al fortunello maledetto
        recentWinner.transfer(address(this).balance);
        // resettiamo il tutto
        // resetto i giocatori, lo stato della lotteria, il numero casuale
        emit PlayersArray(players);
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSE;
        randomness = _randomness;
    }
}
