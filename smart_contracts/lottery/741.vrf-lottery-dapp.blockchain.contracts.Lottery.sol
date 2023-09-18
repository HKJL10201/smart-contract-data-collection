// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

contract Lottery is VRFV2WrapperConsumerBase{

    address payable public lotteryOperator;

    address payable[] public players;

    uint public lotteryId;

    uint256 public lottoPot;

    mapping(address => uint256) public winnings; //maps winners to their winnings 

    mapping (uint => address payable) public lotteryHistory; //array holding previous lottery wiiners

    uint256 public operatorTotalCommission = 0;

    uint256 public vrf_matic = 0;

    uint internal fee = 2 * 10 ** 18; // VRF fee

    uint256 public randomResult; // random number generated from VRF

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 50000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;
    
    // Address LINK - hardcoded for Polygon Mainnet
    address linkAddress = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

    // address WRAPPER - hardcoded for Polygon Mainnet
    address wrapperAddress = 0x4e42f0adEB69203ef7AaA4B7c414e5b1331c14dc;

 constructor()
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        lotteryOperator = payable(msg.sender);
        lotteryId = 0;
    }

    modifier isOperator() {
        require((msg.sender == lotteryOperator), "Caller is not the lottery operator");
        _;
    }

    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    } 

    event lowLink();

    function swapOwner(address payable newOwner) public isOperator {
        lotteryOperator = newOwner;
    }

    //note: VRF requires the gaslimit on the requestRandomness() call to be 400,000
    function getRandomNumber() public isOperator returns (uint256 requestId) {

        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");

         requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        if(LINK.balanceOf(address(this)) <= fee) {
            emit lowLink();
        }

        return requestId;
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords) internal override {
        randomResult = _randomWords[0];
    }

    function getRandomResult() public view returns (uint256) {
        return randomResult;
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getPot() public view returns (uint) {
        return lottoPot;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        players.push(payable(msg.sender));
        lottoPot += msg.value;
    }

    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];

        return reward2Transfer;
    }

    function checkCommissionAmount() public view returns (uint256) {
        return operatorTotalCommission;
    }

    function pickWinner() public isOperator { 

        require(randomResult > 0, "Must have a source of randomness before choosing winner");

        uint index = randomResult % players.length;

        uint256 currPot = lottoPot;

        uint256 vrf_fee = 3 ether;

        currPot -= vrf_fee;

        uint256 com_fee = (currPot * 10)/100;
       
        address winner = players[index];

        lotteryHistory[lotteryId] = players[index];

        winnings[winner] += currPot - com_fee;

        operatorTotalCommission += com_fee;

        vrf_matic += vrf_fee;

        lottoPot = 0;
        players = new address payable[](0);
        randomResult = 0;
    }

    function withdraw(uint256 amount) public payable isOperator {
        require(address(this).balance >= amount);

        lotteryOperator.transfer(amount);
    }

    function withdrawLink() public payable isOperator {
        require(LINK.balanceOf(address(this)) >= 0, "Not enough LINK in contract to withdraw");

        LINK.transfer(lotteryOperator, LINK.balanceOf(address(this)));
    }

    function withdrawWinnings() public payable isWinner {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;

        winner.transfer(reward2Transfer);
    }

    function withdrawCommission() public payable isOperator {
        address payable operator = payable(msg.sender);

        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        operator.transfer(commission2Transfer);
    }

    function withdrawVRF() public payable isOperator {
        address payable operator = payable(msg.sender);

        uint256 vrf_fee = vrf_matic;
        vrf_matic = 0;

        operator.transfer(vrf_fee);
    }

    function IsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }
}