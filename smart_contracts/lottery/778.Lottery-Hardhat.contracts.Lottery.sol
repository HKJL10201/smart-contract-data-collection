//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface ILottyToken {
    function mint(address _recipient) external;
}

contract Lottery is VRFConsumerBaseV2 {
    AggregatorV3Interface priceFeed;
    VRFCoordinatorV2Interface COORDINATOR;
    ILottyToken token;
    address owner;
    address linkTokenAddr;
    address vrfCoordinatorAddr;
    uint32 callbackGasLimit;
    uint16 subscriptionId;
    uint8 requestConfirmations;
    uint8 numWords;
    bytes32 keyHash;
    uint[] randomWords;
    address[] entrants;
    uint256 requestId;

    mapping(address => bool) public isEntered;

    event WinnerDeclared(address winner, uint winnings);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor(
        address _owner,
        address _aggregatorV3Interface, 
        address _linkTokenAddr, 
        address _vrfCoordinatorAddr, 
        uint16 _subscriptionId,
        uint32 _callbackGasLimit,
        uint8 _numWords,
        uint8 _requestConfirmations,
        bytes32 _keyHash
    ) 
        VRFConsumerBaseV2(_vrfCoordinatorAddr) 
    {
        owner = _owner;
        priceFeed = AggregatorV3Interface(_aggregatorV3Interface);
        linkTokenAddr = _linkTokenAddr;
        vrfCoordinatorAddr = _vrfCoordinatorAddr;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinatorAddr);
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }

    function requestRandom() public onlyOwner {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint, 
        uint[] memory _randomWords
    ) internal override  
    {
        randomWords = _randomWords;
    }

    function enterLottery(address _entrant) public payable {
        require(!isEntered[_entrant], "Address already Entered");
        require(_entrant != owner, "Owner cannot participate in Lottery");
        (,int price,,,) = priceFeed.latestRoundData();
        uint priceToWei = uint(price) * 10**10;
        uint minEntranceUsd = 50 * 10**18;
        uint minEntranceEth = (minEntranceUsd * 10**18) / priceToWei;
        require(msg.value >= uint(minEntranceEth), "Wrong amount of Ether");
        isEntered[_entrant] = true;
        entrants.push(_entrant);
    }

    function pickWinner() public onlyOwner {
        uint randomResult = randomWords[0] % entrants.length;
        token.mint(entrants[randomResult]);
        (bool success, ) = 
            payable(entrants[randomResult]).call{value: address(this).balance}("");
        require(success, "Transaction failed");
        emit WinnerDeclared(entrants[randomResult], address(this).balance);
        delete entrants;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        token = ILottyToken(_tokenAddress);
    }

    function getLotteryBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getEntrants() public view returns(address[] memory) {
        return entrants;
    }

}
