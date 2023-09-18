// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/access/Ownable.sol
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public usdEntryFee;
    uint256 public randomness;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE{
        OPEN, // 0
        CLOSED, // 1
        CALCULATING_WINNER // 2
    }
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyHash;
    event RequestedRandomness(bytes32 requestId);


    constructor(
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link)
    {        
        usdEntryFee = 50 * (10**18); // in WEI
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        // $50 USD minimum
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery is not open yet");
        require(msg.value >= getEntranceFee(), "Not enought ETH");
        players.push(msg.sender);
    }

    function getNormalPrice() public view returns(uint256){
        (, int price, , , ) = ethUsdPriceFeed.latestRoundData();        
        uint256 normalPrice =  uint256(price);
        return normalPrice;
    }

    function getAdjustedPrice() public view returns(uint256){
        (, int price, , , ) = ethUsdPriceFeed.latestRoundData();
        // adjusts price to 18 decimal places:
        // price has 8 decimal places, so we multiply it to 10^10
        // to reach 18 decimals.        
        uint256 adjustedPrice = uint256(price) * (10**10);
        return adjustedPrice;
    }    
    
     function getEntranceFee() public view returns (uint256) {
        (, int price, , ,) = ethUsdPriceFeed.latestRoundData();
        // adjusts price to 18 decimal places:
        // price has 8 decimal places, so we multiply it to 10^10
        // to reach 18 decimals.
        uint256 adjustedPrice = uint256(price) * (10**10);

        /*
        As the usdEntryFee and adjustedPrice have both 18 decimal places,
        once you divide one for the other, all decimal places will be canceled out.
        
        Ex:
        
        entrance fee in USD = 50000000000000000000 (50 USD)
        ETH price in USD = 2000000000000000000000
        
        >>> 50000000000000000000 / 2000000000000000000000 = 0.025
        
        The ammount 0.025 is the ETH quantity equivalennt to 50 USD, if 1 ETH = 2000 USD.
        
        In order to match the Units of Measure, which is in WEI, we have to
        convert 0.025 ETH to WEI. We do that by multiplying 0.025 for 10**18.
        
        >>> (0.025) * (10**18) = 25000000000000000 (WEI)
        
        The logic (iun non solidity language) can be:
        
        ethCostToEnter = usdEntryFee / adjustedPrice;
        weiCostToEnter = ethCostToEnter * (10**18)
        return weiCostToEnter
        
        We can achieve the same result by multiplying usdEntryFee by 10**18 
        before dividing by the adjustedPrice, as following:
        
        uint256 costToEnter = (usdEntryFee * 10**18) / (adjustedPrice);
        return costToEnter;
        
        */        
        uint256 costToEnter = (usdEntryFee * 10**18) / (adjustedPrice);
        return costToEnter;
    }

    //this function only works with admin keys
    // onlyOwner is a function belonged to 
    function startLottery() public onlyOwner{
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery yet!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner {
        /*
            In thes function we will make a transaction to resquest a random number
        */
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        bytes32 requestID = requestRandomness(keyHash, fee); 
        emit RequestedRandomness(requestID); 
    }

    function getPlayersLenght() public view returns(uint256) {
        return players.length;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        /*
        It is internal because only VRFCoordinator can call this function
        In thes function we will make a transaction to receive a random number
        */
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER, 
            "You aren't there yet!"
            );
        require(_randomness > 0,"random-not-found");
        uint256 playersLenght = getPlayersLenght();
        uint256 indexOfWinner = _randomness % playersLenght;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance); //the total ammount deposited in this contract will be delivered to the winner
        //Resetting the address array players:
        players = new address payable[](0);
        lottery_state == LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }

}