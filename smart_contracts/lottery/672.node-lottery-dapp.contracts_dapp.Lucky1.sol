pragma solidity ^0.4.22;

import "./Owned.sol";
import "./Random.sol";
import "./Layerprofit.sol";

contract Lucky1 is Owned, Random, layerprofit {

    uint8[] payouts;
    uint8[] winnings_L1;
    uint256[6] randomLucky;

    struct Bet {
        address player;
        uint8 betType;
        uint8 number;
    }
    mapping(address => Bet) public bets;

    uint256 nextRoundTimestamp;

    address[] public players1;

    // mapping (address => uint256) winnings;
    uint256 public pooln_lucky1 = 0;

    uint256 public winner_id;
    uint256 public loser_id;
    uint256 public common1;
    uint256 public common2;
    uint256 public common3;
    uint256 public common4;
    uint256 public initialBalance;
    uint256 public loser_initialBalance;

    uint256 public profit_winner;
    uint256 public profit_loser;
    uint256 public profit_common1;

    struct resultInfo_L1 {
        uint256 winner;
        uint256 loser;
        uint256 common1;
        uint256 common2;
        uint256 common3;
        uint256 common4;
    }
    mapping(uint256 => resultInfo_L1) public resultMap_L1;

    constructor() public payable {
        payouts = [ 1, 5, 10, 50 ]; // 0.1, 0.5, 1, 5
        winnings_L1 = [12, 11, 11, 11, 11, 0 ];
        nextRoundTimestamp = now;
    }

    function bet_lucky1()
        public
        payable
        returns (
            uint256[6],
            uint8[],
            uint256,
            uint256,
            uint256,
            address[],
            uint256,
            uint256
        )
    {
        // (
        //     winner_id,
        //     loser,
        //     common1,
        //     common2,
        //     common3,
        //     common4
        // ) = randomNewLucky();
        randomLucky = randomArrLucky();



        // uint type1 = bets[winner_addr].betType;

        winner_id = randomLucky[0];
        loser_id = randomLucky[5];
        common1 = randomLucky[1];
        common2 = randomLucky[2];
        common3 = randomLucky[3];
        common4 = randomLucky[4];

        uint256 address_balance = address(this).balance;
        initialBalance = players1[winner_id].balance;
        loser_initialBalance = players1[loser_id].balance;
        uint256 common1_initialBalance = players1[loser_id].balance;

        address winner_addr = players1[winner_id];
        allocateProfit(winnings_L1[0], winner_addr, 1);

        address loser_addr = players1[loser_id];
        allocateProfit(winnings_L1[5], loser_addr, 1);

        allocateProfit(winnings_L1[1], players1[common1], 1);
        allocateProfit(winnings_L1[2], players1[common2], 1);
        allocateProfit(winnings_L1[3], players1[common3], 1);
        allocateProfit(winnings_L1[4], players1[common4], 1);

        // address common2_addr = players1[randomLucky[2]];
        // allocateProfit(winnings_L1[2], common2_addr, type1);

        // uint arrayLength = randomLucky.length;
        // for ( uint i=0; i<arrayLength; i++ ){

        //     address addr1 = players1[i];
        //     //test.push(addr1);
        //     // uint balance1 = winnings_L1[i];
        //     // allocateProfit(balance1, addr1, type1);
        // }

        // allocateProfit(address(this).balance, winner_addr, type1);
        profit_winner = players1[winner_id].balance - initialBalance;
        profit_loser = players1[loser_id].balance - loser_initialBalance;
        profit_common1 = players1[common1].balance - common1_initialBalance;

        //winnings[players[winner_id]] = profit;
            // profit,
            // address_balance,
            // bets[addr].betType,
            // bets[addr].player
        return (
            randomLucky,
            winnings_L1,
            address_balance,
            winner_id,
            profit_winner,
            players1,
            profit_loser,
            profit_common1
        );
    }


    function participate(uint8 number) public payable {
        require(msg.value >= .01 ether);

        players1.push(msg.sender);

        bets[msg.sender].betType = 1;
        bets[msg.sender].player = msg.sender;
        bets[msg.sender].number = number;

    }

    // function random() private view returns (uint256) {
    //     return
    //         uint256(
    //             keccak256(
    //                 abi.encodePacked(block.difficulty, block.timestamp, players1)
    //             )
    //         );
    // }

    // function pickWinner() public onlyOwner {
    //     require(players.length > 0);

    //     uint256 index = random() % players.length;
    //     players[index].transfer(address(this).balance);

    //     players = new address[](0);
    // }

    function getPlayers() public view returns (address[]) {
        return players1;
    }

}
