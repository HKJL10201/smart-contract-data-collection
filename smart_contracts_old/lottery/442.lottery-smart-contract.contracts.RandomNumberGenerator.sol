// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILottery.sol";

/**
 * @title RandomNumberGenerator Contract
 */
contract RandomNumberGenerator is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;

    address public lotteryAddr;
    uint256 private requestCount;
    uint256[] private randomNumbers;    

    /// @notice Event emitted when contract is deployed.
    event RandomNumberGeneratorDeployed();

    /// @notice Event emitted when chainlink verified random number arrived or requested.
    event randomNumberArrived(
        bool arrived,
        uint256 randomNumber,
        bytes32 batchID
    );

    /// @notice Event emitted when lottery address set.
    event LotteryAddressSet(address lotteryAddr);

    modifier onlyLottery() {
        require(
            msg.sender == lotteryAddr,
            "RandomNumberGenerator: Game is not approved"
        );
        _;
    }

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Polygon(Matic) Mainnet
     * Chainlink VRF Coordinator address: 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
     * LINK token address:                0xb0897686c545045aFc77CF20eC7A532E3120E0F1
     * Key Hash:                          0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
     * Fee : 0.0001LINK
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link // LINK Token
        )
    {
        keyHash = _keyHash;
        fee = _fee;

        emit RandomNumberGeneratorDeployed();
    }

    /**
     * @dev Public function to request randomness and returns request Id. This function can be called by only apporved games.
     */
    function getRandomNumber()
        external
        onlyLottery
        returns (bytes32 requestId)
    {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");

        bytes32 _requestId = requestRandomness(keyHash, fee);
        requestCount ++;

        return _requestId;
    }

    /**
     * @dev Callback function used by VRF Coordinator. This function calls the play method of current game contract with random number.
     * @param _requestId Request Id
     * @param _randomness Random Number
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        randomNumbers[requestCount - 1] = _randomness;

        if(requestCount == 3) {
            ILottery lottery = ILottery(lotteryAddr);
            lottery.declareWinner(randomNumbers);
            requestCount = 0;
            delete randomNumbers;
        }

        emit randomNumberArrived(true, _randomness, _requestId);
    }

    /**
     * @dev External function to set the lottery contract address.
     * @param _lotteryAddr Lottery Address
     */
    function setLotteryAddress(address _lotteryAddr) external onlyOwner {
        lotteryAddr = _lotteryAddr;

        emit LotteryAddressSet(_lotteryAddr);
    }
}
