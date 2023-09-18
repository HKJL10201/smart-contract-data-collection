// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LotteryDapp is VRFConsumerBaseV2 {
    // Library
    using Strings for uint256;

    // CONSTANTS
    address private constant LINK_TOKEN_CONTRACT =
        0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address private constant VRF_COORDINATOR_CONTRACT_ADDR =
        0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    VRFCoordinatorV2Interface private constant VRF_COORDINATOR_CONTRACT =
        VRFCoordinatorV2Interface(VRF_COORDINATOR_CONTRACT_ADDR);
    bytes32 private constant KEY_HASH =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint64 private constant SUBSCRIPTION_ID = 2849;

    // STATE VARS
    uint256 public immutable maxPlayers;
    uint256 public immutable entryFee;
    address payable[] public playersJoined;
    uint256 private _requestId;

    // Modifiers
    modifier validFee() {
        require(
            msg.value == entryFee,
            string.concat("INVALID FEE SENT; SEND: ", entryFee.toString())
        );
        _;
    }

    modifier canAddPlayer() {
        require(
            playersJoined.length < maxPlayers,
            string.concat("MAX PLAYERS REACHED: ", maxPlayers.toString())
        );
        _;
    }

    modifier correctRequestId(uint256 _requestIdToCheck) {
        require(
            _requestId == _requestIdToCheck,
            "VRF REQUEST ID DOES NOT MATCH"
        );
        _;
    }

    // Events
    event PlayerJoined(address playerAddr);
    event GameFinished(address payable playerWinnerAddr);

    // Constructor
    constructor(uint256 _maxPlayers, uint256 _entryFee)
        VRFConsumerBaseV2(VRF_COORDINATOR_CONTRACT_ADDR)
    {
        maxPlayers = _maxPlayers;
        entryFee = _entryFee;
    }

    // Join lottery
    function joinLottery() external payable canAddPlayer validFee {
        playersJoined.push(payable(msg.sender));
        emit PlayerJoined(msg.sender);
        if (playersJoined.length == maxPlayers - 1) {
            _requestId = VRF_COORDINATOR_CONTRACT.requestRandomWords(
                KEY_HASH,
                SUBSCRIPTION_ID,
                3,
                30000,
                1
            );
        }
    }

    // Get back random value and finish game
    function fulfillRandomWords(
        uint256 _requestIdReceived,
        uint256[] memory _randomWords
    ) internal override correctRequestId(_requestIdReceived) {
        address payable winnerPlayer = playersJoined[
            (_randomWords[0] % maxPlayers)
        ];
        (bool success, ) = winnerPlayer.call{value: (maxPlayers * entryFee)}(
            ""
        );
        require(success, "PLAYER COULD NOT BE REWARDED");
        emit GameFinished(winnerPlayer);
        delete playersJoined;
    }
}
