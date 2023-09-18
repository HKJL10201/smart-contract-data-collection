// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Raffle__NotEnoughEther();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle_upkeepNotNeeded(uint256 Balance, uint256 raffleState, uint256 numPlayers);

/** @title Raffle Contract
*   @author Nacho Díaz
*   @notice This contract creates an autonomous and decentraliced SmartContract
*   @dev Implements Chainlink VRFv2 & Keepers*/ 

//Hereda las prpiedades de VRFConsumerBaseV2 y KeeperCompatible
contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Types */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    VRFCoordinatorV2Interface private immutable i_COORDINATOR;
    uint256 private immutable i_precioEntrada;
    address payable[] private s_players;
    //Máximo precio en wei por gas que estamos dispuestos a pagar. En el curso se llama gasLane
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFRMATIONS = 1;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant NUM_WORDS = 1;

    /* Lottery Variables */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval; //No va a a ser modificada y ahorramos gas

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player);


    /* Functions */
    constructor(
        address vrfCoordinatorV2, //contract -> deploy mocks needed
        uint256 precioEntrada,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_precioEntrada = precioEntrada;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        if (msg.value < i_precioEntrada) {
            revert Raffle__NotEnoughEther();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    //Pedimos un nunmero aleatorio -> elegimos ganador -> transferimos dinero
    //Esto lo hacemos en dos tx para evitar problemas de seguridad

    /**
     *@dev With this function the Chainlink Keeper nodes call, they look for the UpkeepNeeded to return true
     *The following function should return true, that happends if:
     *1. The interval has passed
     *2. There is at least 2 players
     *3. The subscriptios is funded with Link
     *4. Lottery is in an open state. Because while we wait the random number, nobody can eter the raffle */

    
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* PerformData */) {
        bool open = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool players = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (open && timePassed && players && hasBalance);
        return (upkeepNeeded, "0x0");
    }



    function performUpkeep(bytes calldata /* PerformData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle_upkeepNotNeeded(address(this).balance, uint256(s_raffleState), s_players.length);

        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_COORDINATOR.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    //Cogemos la función de Chainlink docs,
    function fulfillRandomWords(
        uint256, /* requestId ->La comentamos pq no la usamos en la función*/
        uint256[] memory randomWords
    ) internal override {
        uint256 indexWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }


    /* View / Pure functions */

    function getPrecioentrada() public view returns (uint256) {
        return i_precioEntrada;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    //La ponemos pure pq la información se coje del bytecode, no del SC.
    function getNumWords() public pure returns (uint16) {
        return NUM_WORDS;
    }

    function getNumPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getRequestConfirmations() public pure returns (uint16) {
        return REQUEST_CONFRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getKeyHash() public view returns (bytes32) {
        return i_keyHash;
    }
    
    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    /* function getopen() public view returns (bool) {
        return open;
    }
     
    function gettimePassed() public view returns (bool) {
        return timePassed;
    }

    function getplayers() public view returns (bool) {
        return players;
    }

    function gethasBalance() public view returns (bool) {
        return hasBalance;
    } */
}
