// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
 
contract Lottery {
    uint private entryPrice = 0.01 ether;
    address private immutable owner;
    uint private poolSize = 3;
    address payable[] public addresses;
    address payable[5] public winners;
    uint private maintenanceCharge = 0;
    uint private lotteryNumber = 1;

    constructor () payable {
        owner = msg.sender;
    }

    function getPoolSize() public view returns(uint){
        return poolSize;
    }

    function getParticipationSize() public view returns(uint){
        return addresses.length;
    }

    function getUserParticipation(address  _address) public view returns(uint){
        uint userOccurance = 0;
        for (uint i=0; i<addresses.length; i++) {
            if(addresses[i]==_address){
                userOccurance++;
            }    
        }
        return userOccurance;
    }

    function syncDetail(address _address) public view returns(uint, uint, uint, uint, address payable[5] memory){
        uint _poolSize = getPoolSize();
        uint _participationSize = getParticipationSize();
        uint _userParticipation = getUserParticipation(_address);
        //User participation is number of times user has participated
        return (_poolSize, _participationSize, _userParticipation,lotteryNumber, winners);
    }

    function setPoolSize(uint _poolSize) public{
        require(msg.sender==owner);
        poolSize = _poolSize;
    }

    function getLotteryBalance() public view returns(uint){
        return address(this).balance;
    }

    function getMaintainanceCollection() public view returns(uint){
        return maintenanceCharge;
    }

    function transferMaintainanceCharge(address payable _to) public{
        require(msg.sender==owner);
        _to.transfer(maintenanceCharge);
    }
 
    receive () external payable {
        require(msg.value==entryPrice, "Value less then entry fees.");
        addresses.push(payable(msg.sender));
        if(addresses.length>=poolSize){
            finalizeLottery();
        }
    }

    function randomIndex() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, addresses.length)))% addresses.length;
    }

    function storeNewWinnerAddress(address payable _winner) public{
        address payable[5] memory _winners;
        for (uint i=0; i<winners.length-1; i++) {
           _winners[i] = winners[i+1];
        }
        _winners[winners.length-1] = _winner;
        winners = _winners;
        lotteryNumber = lotteryNumber+1;
    }

    function finalizeLottery() public{
        address payable winner = addresses[randomIndex()];

        uint winAmount = getLotteryBalance()*99/100; //1% service charge
        maintenanceCharge = getLotteryBalance()*1/100;
        winner.transfer(winAmount);
        //the below function have some error
        storeNewWinnerAddress(winner);
        //Reset the lottery, requires gas to execute wallet must have balance
        addresses = new address payable[](0);
    }
 
}
