// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {

    address private owner;
    uint256 public id;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    
    struct lotteryDetails{
        uint256 lotteryId;
        uint256 lotteryPrice;
        uint256 ownerShare; // in percentage
        uint256 timeStart;
        uint256 timeEnd;
        address[] participants;
        uint256 totalAmount;
    }
    
    struct winnerDetails{
        uint256 lotteryId;
        address winnerAddress;
        uint256 timestamp;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 prizeAmount;
        bool claimed;
    }
    
    struct userDetails{
        uint256[] winHistory; // lottery id's that have won by user
        uint256 totalPrizeWon; // total prize won by user
    }
    
    mapping(uint256 => lotteryDetails) public Lotteries; //saving all lottey info
    mapping(uint256 => winnerDetails) public Winners; // saving all winners info
    mapping(address => userDetails) public userAccounts; // saving individual user info

    //------------------------rinkbey----------------------------------
    constructor ()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {

        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        owner = msg.sender;
    }

    //------------------------kovan----------------------------------
    // constructor ()
    //     VRFConsumerBase(
    //         0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
    //         0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    //     )
    // {

    //     keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    //     fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        
    // }
    
    modifier onlyOwner {
       require(msg.sender == owner, 'Only owner has permissions.');
      _;
    }

    function getRandomNumber() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    // Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = (randomness % Lotteries[id].participants.length);
    }
    
    // owner setting lottery details
    function setLottery(uint256 _days, uint256 _price, uint _ownershare) public onlyOwner returns(bool) {
        id++;
        Lotteries[id].timeStart = block.timestamp;
        Lotteries[id].timeEnd = Lotteries[id].timeStart + (_days * 60); 
        Lotteries[id].lotteryPrice = _price;
        Lotteries[id].ownerShare = _ownershare;
        return true;
    }


    // participants can participate in the current ongoing lottery
    function Participate() public payable returns(bool){
        require(msg.sender != owner, 'owner cant participate');
        require(msg.value == Lotteries[id].lotteryPrice, 'Amount is not equal to the participating price');
        require(Lotteries[id].timeStart < block.timestamp , 'Lottery is not started yet');
        require(block.timestamp < Lotteries[id].timeEnd , 'This lottery is finished');
        Lotteries[id].participants.push(msg.sender);
        Lotteries[id].totalAmount += msg.value;
        return true;
    }
    
  
    //   owner will draw winner from the lottery
    function DrawLottery() public payable onlyOwner returns(address){
        require(Lotteries[id].timeEnd < block.timestamp, 'lottery is still on');
        // generate random winner index
        getRandomNumber();
        // calculate prize money for lottery
        uint256 prizeMoney = Lotteries[id].totalAmount - ((Lotteries[id].totalAmount * Lotteries[id].ownerShare)/100);
        address LuckyWinner = Lotteries[id].participants[randomResult];

        // set winner details for this lottery
        Winners[id].lotteryId = id;
        Winners[id].winnerAddress = LuckyWinner;
        Winners[id].timestamp = block.timestamp;
        Winners[id].prizeAmount = prizeMoney;

        // set user account details, i.e winnig histories
        userAccounts[LuckyWinner].winHistory.push(id);
        userAccounts[LuckyWinner].totalPrizeWon += prizeMoney;

        return LuckyWinner;
    }
    
    function getParticipants() public view returns( address[] memory){
        return Lotteries[id].participants;
    }

    // winner can claim for the lottery prize
    function claimPrize(uint256 _id) public payable {
       require(Winners[_id].claimed == false, 'Already Claimed');
        require(Winners[_id].winnerAddress == msg.sender, 'You are not winner');
        uint256 prizeMoney = Winners[_id].prizeAmount;
        Winners[_id].claimed = true;
        payable(msg.sender).transfer(prizeMoney);
    }

}
    

