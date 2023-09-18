// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Base.sol";

contract Kuji is VRFConsumerBase, Base {
    using SafeMath for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public constant WINNING_NUMBER = 1;
    uint256 public constant ROLL_IN_PROGRESS = 42;
    uint256 public probability;

    mapping(bytes32 => address) public s_rollers;
    mapping(address => uint256) public s_results;

    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);
    event PrizeSent(address indexed winner, uint256 amount);

    constructor(
        address vrfCoordinator,
        address link,
        bytes32 _keyHash,
        uint256 _probability
    ) VRFConsumerBase(vrfCoordinator, link) {
        keyHash = _keyHash;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        probability = _probability;
    }

    function getLinkBalance() public view returns (uint256 linkBalance) {
        return LINK.balanceOf(address(this));
    }

    function rollDice(address roller)
        public
        onlyOwner
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK to pay fee"
        );
        require(s_results[roller] == 0, "Already rolled");
        requestId = requestRandomness(keyHash, fee);
        s_rollers[requestId] = roller;
        s_results[roller] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, roller);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 random_value = randomness.mod(probability).add(1);

        address player = s_rollers[requestId];
        s_results[player] = random_value;

        emit DiceLanded(requestId, random_value);
    }

    function givePrize(address player) public {
        if (getResult(s_results[player])) {
            withdrawLINK(player, getLinkBalance());

            emit PrizeSent(player, getLinkBalance());
        }
    }

    // from solidity document https://docs.soliditylang.org/en/v0.8.6/common-patterns.html
    function withdrawLINK(address to, uint256 value)
        public
        onlyOwner
        noReentrant
    {
        require(LINK.transfer(to, value), "Not enough LINK");
    }

    function result(address player) public view returns (string memory) {
        require(s_results[player] != 0, "Dice not rolled");
        require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");

        return
            getResult(s_results[player])
                ? "Congrats, you won."
                : "Sorry, you lost.";
    }

    function getResult(uint256 id) private pure returns (bool) {
        return id == WINNING_NUMBER;
    }
}
