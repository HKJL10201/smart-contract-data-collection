// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public masterAccount;
    address public dealer;

    //list of numbers choiced by players
    uint[] numbers;
    //number => players choosing this number
    mapping(uint => address[]) db; 
    //player joined => true
    mapping(address => bool) checkExistence;

    //round status
    bool isEnded;
    //round counter
    uint round;
    //list of winners in current round
    address[] winners;
    //lucky number in current round
    uint luckyNumber;
    //reward will be sent to each winner in current round
    uint winningReward;

    constructor() {
        //hard-coded: default master account
        masterAccount = 0x4bC4bd4A73d652b2B63CCd35493366921C295CDA;

        //the dealer who deploys this smart contract
        dealer = msg.sender;

        //first round has not started yet
        isEnded = true;

        round = 0;
        luckyNumber = 0;
        winningReward = 0;
    }

    //view total balance of this smart contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    //view list of numbers choiced by players
    function getNumbers() public view returns (uint[] memory) {
        return numbers;
    }

    //view players choosing this specific number
    function getPlayerByNumber(uint number) public view returns (address[] memory) {
        return db[number];
    }

    //check if this player has already joined in this round
    function isExisted(address add) public view returns (bool) {
        return checkExistence[add];
    }

    //check if this round is end
    function isGameEnded() public view returns (bool) {
        return bool(isEnded);
    }

    //view current round
    function getCurRound() public view returns (uint) {
        return round;
    }

    //view list of winners
    function getWinners() public view returns (address[] memory) {
        return winners;
    }

    //view the lucky number
    function getLuckyNumber() public view returns (uint) {
        return luckyNumber;
    }

    //view reward each winners will be received
    function getWinningReward() public view returns (uint) {
        return winningReward;
    }

    //view the number of players in this round
    function getTotalPlayers() public view returns (uint) {
        return numbers.length;
    }
    //

    function play(uint bettingNumber) public payable {
        //round has to be start - dealer can't be a player - amount to join is exactly 1 ether - player joins lottery only once per round - 
        //max total players in 1 round is 100 - bettingNumber is from 0 to 99
        require(isEnded == false && msg.sender != dealer && msg.value == 1 ether && checkExistence[msg.sender] == false 
                && numbers.length < 100 && bettingNumber >= 0 && bettingNumber < 100);

        //player can join lottery game only once
        checkExistence[msg.sender] = true;
        numbers.push(bettingNumber);
        db[bettingNumber].push(payable(msg.sender));
    }

    function changeMasterAccount(address account) public onlyDealer {
        //master account should be different with dealer account - the round must be end before change master account
        require(account != dealer && isEnded == true);
        masterAccount = account;
    }

    function startGame() public onlyDealer {
        //this round has to be end before start
        require(isEnded == true);

        //reset state of this smart contract
        for (uint i = 0; i < numbers.length; i++) {
            if (db[numbers[i]].length > 0) {
                for (uint j = 0; j < db[numbers[i]].length; j++) {
                    delete checkExistence[db[numbers[i]][j]];
                }
                delete db[numbers[i]];
            }
        }
        numbers = new uint[](0);
        
        //start new round
        isEnded = false;
        round++;
    }

    
    function endGame() public onlyDealer {
        //this round has to be start before end
        require(isEnded == false);

        //lucky number is always from 0 to 99
        luckyNumber = uint(block.timestamp % 100);

        //TODO: for testing
        //luckyNumber = 1; 

        //get list of winners
        winners = db[luckyNumber];

        //if total winners > 1 the reward will be shared
        if (winners.length > 0) {
            //each winner will be received their winningReward
            winningReward = uint((getBalance() * 9 / 10)/winners.length);
            for (uint i = 0; i < winners.length; i++) {
                //transfer reward to each winner
                payable(winners[i]).transfer(winningReward);
            }
        //ortherwise no one should be received the reward
        } else {
            winningReward = 0;
        }

        //transfer the rest of balance to master account
        payable(masterAccount).transfer(getBalance());

        //end round
        isEnded = true;
    }

    //restrict the use for only Dealer
    modifier onlyDealer() {
        require(msg.sender == dealer);
        _;
    }

}