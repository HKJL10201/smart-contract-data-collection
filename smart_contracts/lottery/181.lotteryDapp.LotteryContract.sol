pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract simpleLottery is VRFConsumerBase{

    // chainlink variables 
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;


    //created struct to hold data about user, name and wager ammount
    struct LotteryData{
        uint wager;
        string name;
    }
// mapping to hold user address and strcut info
    mapping(address => LotteryData) lotteryMap;
    address[] addressList;

/**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }


    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        //random number between 0-19
        randomResult = (randomness % addressList.length);
    }




    //gets users wager and name
    function getInformation(uint _wager, string memory _name) public {

        //fills mapping with the callers addrress and the values inputted
        lotteryMap[msg.sender] = LotteryData(_wager, _name);

        //pushes user address to address list to tally how many users
        addressList.push(msg.sender);
    }



    //displays the winner of the lottery
    function displayWinner() public view returns(LotteryData memory){

        //finds winnwer by choosing random number within the list of user addresses
        //fetches lottery data struct from mapping
        return lotteryMap[addressList[randomResult]];
    }

    








}
