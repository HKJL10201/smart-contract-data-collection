pragma solidity ^0.4.24;

import "./ECVerify.sol";

contract Dice_SC {

    /*
     *   constant
     */

    uint256 constant MAX_MASK_MODULO = 40;

    /*
     *   state
     */

    // roundIdentifier is keccak256(channelIdentifier, round)
    mapping (bytes32 => DiceInfo) public roundIdentifier_to_diceInfo;

    struct DiceInfo {
        address positive;

        address negative;

        uint256 betMask;

        uint256 modulo;

        bytes32 initiatorHashR;

        bytes32 acceptorR;

        // 0 = non-existent or settled
        // 1 = waiting for initiator reveal 
        uint8 state; 

        uint256 lastRevealBlock;
    }

    uint256 public revealWindow;

    mapping (bytes32 => address) roundIdentifier_to_winner;

    /*
     *   constructor
     */

    constructor(uint256 _revealWindow) public {
        require(_revealWindow > 0, "invalid reveal window");

        revealWindow = _revealWindow;
    }

    /*
     *   modifiers
     */


    /*
     *   public function
     */

    /// @notice initiator settle game
    /// @param channelIdentifier channelIdentifier of participants
    /// @param round game round
    /// @param betMask mask of bet
    /// @param modulo kind of game
    /// @param positive initiator address
    /// @param negative acceptor address
    /// @param initiatorHashR hash of initiator random
    /// @param initiatorSignature signature of initiator 
    /// @param acceptorR acceptor random
    /// @param acceptorSignature signature of acceptor 
    /// @param initiatorR initiator random
    function initiatorSettle (
        bytes32 channelIdentifier,
        uint256 round,
        uint256 betMask,
        uint256 modulo,
        address positive,
        address negative,
        bytes32 initiatorHashR,
        bytes initiatorSignature,
        bytes32 acceptorR,
        bytes acceptorSignature,
        bytes32 initiatorR
    )
        public
    {
        require(initiatorHashR == keccak256(abi.encodePacked(initiatorR)), "initiatorR should be correct");

        address recoveredInitiator = recoverInitiator(
            channelIdentifier, 
            round, 
            betMask, 
            modulo, 
            positive, 
            negative, 
            initiatorHashR, 
            initiatorSignature
        );
        require(recoveredInitiator == positive, "signature should be signed by initiator");

        bytes32 acceptorMessageHash = keccak256(
            abi.encodePacked(
                address(this),
                channelIdentifier,
                round,
                betMask,
                modulo,
                positive,
                negative,
                initiatorHashR,
                initiatorSignature,
                acceptorR
            )
        );
        //address recoveredAcceptor = ECVerify.ecverify(acceptorMessageHash, acceptorSignature);
        require(ECVerify.ecverify(acceptorMessageHash, acceptorSignature) == negative, "signature should be signed by initiator");

        address winner = settleBet (
            betMask,
            modulo,
            initiatorR,
            acceptorR,
            positive,
            negative
        );

        bytes32 roundIdentifier = getRoundIdentifier(
            channelIdentifier,
            round
        );

        roundIdentifier_to_winner[roundIdentifier] = winner;

        emit InitiatorSettled(msg.sender, negative, roundIdentifier, winner);
    }

    /// @notice acceptor settle game
    /// @param channelIdentifier channelIdentifier of participants
    /// @param round game round
    /// @param betMask mask of bet
    /// @param modulo kind of game
    /// @param positive initiator address
    /// @param negative acceptor address
    /// @param initiatorHashR hash of initiator random
    /// @param initiatorSignature signature of initiator 
    /// @param acceptorR acceptor random
    function acceptorSettle (
        bytes32 channelIdentifier,
        uint256 round,
        uint256 betMask,
        uint256 modulo,
        address positive,
        address negative,
        bytes32 initiatorHashR,
        bytes initiatorSignature,
        bytes32 acceptorR
    )
        public
    {
        require(msg.sender == negative, "tx should be made by acceptor");

        address recoveredInitiator = recoverInitiator(
            channelIdentifier, 
            round, 
            betMask, 
            modulo, 
            positive, 
            negative, 
            initiatorHashR, 
            initiatorSignature
        );
        require(recoveredInitiator == positive, "signature should be signed by initiator");

        bytes32 roundIdentifier = getRoundIdentifier(
            channelIdentifier,
            round
        );

        require(roundIdentifier_to_winner[roundIdentifier] == 0x0, "should not settle again when already settled");

        DiceInfo storage diceInfo = roundIdentifier_to_diceInfo[roundIdentifier];
        diceInfo.betMask = betMask;
        diceInfo.modulo = modulo;
        diceInfo.positive = positive;
        diceInfo.negative = negative;
        diceInfo.initiatorHashR = initiatorHashR;
        diceInfo.acceptorR = acceptorR;
        diceInfo.lastRevealBlock = block.number + revealWindow;
        diceInfo.state = 1;

        roundIdentifier_to_winner[roundIdentifier] = negative;

        emit AcceptorSettled(positive, negative, roundIdentifier, diceInfo.lastRevealBlock);
    }

    /// @notice initiator should reveal random after acceptor settled
    /// @param channelIdentifier channelIdentifier of participants
    /// @param round game round
    /// @param initiatorR initiator random
    function initiatorReveal (
        bytes32 channelIdentifier,
        uint256 round,
        bytes32 initiatorR
    )
        public
    {
        bytes32 roundIdentifier = getRoundIdentifier(
            channelIdentifier,
            round
        );

        DiceInfo storage diceInfo = roundIdentifier_to_diceInfo[roundIdentifier];
        require(diceInfo.state == 1, "state should be waiting for reveal");

        require(keccak256(abi.encodePacked(initiatorR)) == diceInfo.initiatorHashR, "initiatorR should be correct");

        require(block.number <= diceInfo.lastRevealBlock, "reveal time window should be open");

        address winner = settleBet(
            diceInfo.betMask,
            diceInfo.modulo,
            initiatorR,
            diceInfo.acceptorR,
            diceInfo.positive,
            diceInfo.negative
        );
        roundIdentifier_to_winner[roundIdentifier] = winner;

        emit InitiatorRevealed(diceInfo.positive, diceInfo.negative, roundIdentifier, winner);

        delete roundIdentifier_to_diceInfo[roundIdentifier];
    }

    /// @notice get lock settle result by payment contract
    /// @param roundIdentifier lock id
    function getResult (
        bytes32 roundIdentifier
    )
        view
        public
        returns (address)
    {
        DiceInfo storage diceInfo = roundIdentifier_to_diceInfo[roundIdentifier];

        if (diceInfo.state == 1) {
            require(block.number > diceInfo.lastRevealBlock, "reveal time window should be closed");
        } 

        return roundIdentifier_to_winner[roundIdentifier];
    }

    /*
     *   event
     */

    event InitiatorSettled (
        address indexed initiator,
        address indexed acceptor,
        bytes32 roundIdentifier,
        address winner
    );

    event AcceptorSettled (
        address indexed initiator,
        address indexed acceptor,
        bytes32 roundIdentifier,
        uint256 lastRevealBlock
    );

    event InitiatorRevealed (
        address indexed initiator,
        address indexed acceptor,
        bytes32 roundIdentifier,
        address winner
    );

    // event DiceResultSettled (
    //     address indexed initiator,
    //     address indexed acceptor,
    //     uint256 round,
    //     address winner
    // );

    /*
     *   private function
     */
     
    function settleBet (
        uint256 betMask,
        uint256 modulo,
        bytes32 initiatorR,
        bytes32 acceptorR,
        address positive,
        address negative
    )
        pure
        internal
        returns (address winner)
    {
        bytes32 entropy = keccak256(
            abi.encodePacked(
                initiatorR, 
                acceptorR
            )
        );
        uint256 dice = uint256(entropy) % modulo;

        if (modulo <= MAX_MASK_MODULO) {
            if (((2 ** dice) & uint40(betMask)) != 0) {
                winner = positive;
            } else {
                winner = negative;
            }
        } else {
            if (dice < betMask) {
                winner = positive;
            } else {
                winner = negative;
            }
        }
    }

    function recoverInitiator (
        bytes32 channelIdentifier,
        uint256 round,
        uint256 betMask,
        uint256 modulo,
        address positive,
        address negative,
        bytes32 initiatorHashR,
        bytes signature
    )
        view
        internal
        returns (address)
    {
        bytes32 initiatorMessageHash = keccak256(
            abi.encodePacked(
                address(this),
                channelIdentifier,
                round,
                betMask,
                modulo,
                positive,
                negative,
                initiatorHashR
            )
        );

        return ECVerify.ecverify(initiatorMessageHash, signature);
    }

    function getRoundIdentifier (
        bytes32 channelIdentifier,
        uint256 round
    )
        pure
        internal
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                channelIdentifier,
                round
            )
        );
    }
}