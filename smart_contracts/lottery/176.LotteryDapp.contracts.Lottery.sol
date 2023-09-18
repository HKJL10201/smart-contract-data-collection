//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error Lottery__NotEnoughETHEntered();
error Lottery__TransferFailed();

contract Lottery is VRFConsumerBaseV2{
    uint private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    address private s_recentWinner;

    constructor(address vrfCoordinatorV2 ,  //0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D on Goerli testnet
    uint entranceFee,                       //0.01 ETH
    bytes32 gasLane,                        //0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
    uint64 subscriptionId,                  //9802
    uint32 callbackGasLimit)                //500000 gas
    VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee=entranceFee;
        i_vrfCoordinator=VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane=gasLane;
        i_subscriptionId=subscriptionId;
        i_callbackGasLimit=callbackGasLimit;
    }

    function enterLottery() public payable{
        if(msg.value<i_entranceFee){
            revert Lottery__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));
    }

    function requestRandomWinner() external {
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override{
        uint indexOfWinner = randomWords[0]%s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        (bool success, ) = recentWinner.call{value:address(this).balance}(""); 
        if(!success){
            revert Lottery__TransferFailed();
        }
    }

    /* View/Pure functions */
    function getEntranceFee() public view returns(uint){
        return i_entranceFee;
    }

    function getPlayer(uint index) public view returns(address){
        return s_players[index];
    }

    function getRecentWinner() public view returns(address){
        return s_recentWinner;
    }

    function getNumberOfPlayers() public view returns(uint){
        return s_players.length;
    }
}