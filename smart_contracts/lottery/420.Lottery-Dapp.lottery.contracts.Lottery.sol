// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./MyToken.sol";

contract Lottery is VRFConsumerBase {
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    MyToken public token;
    uint public pot = 0;

    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint internal fee;        // fee to get random number
    uint public randomResult;

    uint256 public costTicket = 5 * (10**18);

    // ERC20 Token
    // LTRToken public token;

    constructor(MyToken _token)
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK token address
        ) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 0.1 * 10 ** 18;    // 0.1 LINK

            owner = msg.sender;
            lotteryId = 1;
            token = _token;
        }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        token.setApproval(msg.sender, address(this), costTicket);
        token.transferFrom(msg.sender, address(this), costTicket);
        //require(msg.value > .01 ether);
        //pot
        pot += costTicket/10**18;
        // address of player entering lottery
        players.push(payable(msg.sender));
    }

    function pickWinner() public onlyowner {
        getRandomNumber();
    }

    function payWinner() public {
        require(randomResult > 0, "Must have a source of randomness before choosing winner");
        uint index = randomResult % players.length;
        //players[index].transfer(address(this).balance);

        token.setApproval(address(this), players[index], pot * (10**18));
        token.transfer(players[index], pot * (10**18));

        lotteryHistory[lotteryId] = players[index];
        lotteryId++;
        
        // reset the state of the contract
        players = new address payable[](0);
    }

    function getPot() public returns (uint) {
        return pot;
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}

