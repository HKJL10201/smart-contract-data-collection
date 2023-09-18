// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract theLottery is VRFConsumerBase {
    struct participant {
        uint256 amount_paid;
        address payable participant_address;
    }

    uint256 public lotteryId;
    mapping(uint256 => participant) public recordOfWinners;
    address public admin;
    //map uses first index to 'reset' over once lottery finishes. High waste but for demonstration purposes.
    mapping(uint256 => mapping(address => uint256))
        public participants_contribution;
    address payable[] public participants;
    //participant[] public participants;

    uint256 internal fee; // fee needed to retrieve random number from Chainlink
    bytes32 internal keyHash; // identifies the specific Chainlink oracle
    uint256 public randomResult;
    uint256 public game_number;

    //participant new_player;

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, //the VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 //the address of LINK token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK

        admin = msg.sender;
        lotteryId = 1;
        game_number = 0;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK in contract"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        payWinner();
    }

    function getWinnerByLottery(uint256 index_lotteries)
        public
        view
        returns (participant memory)
    {
        return recordOfWinners[index_lotteries];
    }

    function getLotteryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    function enter() public payable {
        require(msg.value >= 0.02 ether);
        if (participants_contribution[game_number][msg.sender] == 0) {
            participants.push(payable(msg.sender));
            participants_contribution[game_number][msg.sender] = msg.value;
        } else {
            participants_contribution[game_number][msg.sender] += msg.value;
        }

        // avoid duplicate player in participants
    }

    /*
    receive() external payable {
        require(msg.value >= 0.02 ether);
        //new_player.participant_address = payable(msg.sender);
        //new_player.amount_paid = payable(msg.sender);
        //participants.push(payable(msg.sender));
        
    }
    */

    function pickWinner() public onlyOwner {
        require(participants.length > 1);
        getRandomNumber();
    }

    function payWinner() public {
        require(
            randomResult > 0,
            "Must have a source of randomness before choosing winner"
        );
        uint256 index = randomResult % participants.length;
        recordOfWinners[lotteryId].amount_paid = address(this).balance;
        recordOfWinners[lotteryId].participant_address = participants[index];
        participants[index].transfer(address(this).balance);
        lotteryId++;

        // reset the state of the contract
        participants = new address payable[](0);
        game_number++;
        randomResult = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }
}
