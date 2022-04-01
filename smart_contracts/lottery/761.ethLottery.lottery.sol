pragma solidity^0.5.0;

contract Lottery {
    address payable manager;
    address payable winner;
    address payable [] lotteryPlayers;

    uint public winningNum;
    uint public roundNum;
    uint public rewardRate=80;
    uint public winningReward;
    uint public lotteryBet=1 ether;

    uint public drawStartTime=now;
    uint public drawEndTime=now + 30 minutes;
    constructor() public {
        manager = msg.sender;
    }

    function throwIn() public payable{
        require(msg.value == lotteryBet);
        require(now < drawStartTime);
        lotteryPlayers.push(msg.sender);
    }

    modifier managerLimit {
        require(msg.sender == manager);
        _;
    }

    //event test(uint,uint);
    function draw() public managerLimit  {
        require(lotteryPlayers.length != 0);
        require(now >= drawStartTime && now < drawEndTime);
        bytes memory randomInfo = abi.encodePacked(now,block.difficulty,lotteryPlayers.length);
        bytes32 randomHash =keccak256(randomInfo);
        winningNum = uint(randomHash)%lotteryPlayers.length;
        winner=lotteryPlayers[winningNum];

        winningReward = address(this).balance*rewardRate/100;
        winner.transfer(winningReward);
        //emit test(reward,address(this).balance);
        manager.transfer(address(this).balance);
        roundNum++;
        drawStartTime+=1 days;
        drawEndTime+=1 days;
        delete lotteryPlayers;
    }
    function getBalance()public view returns(uint){
        return address(this).balance;
    }
    function getWinner()public view returns(address){
        return winner;
    }
    function getManager()public view returns(address){
        return manager;
    }

    function getLotteryPlayers() public view returns(address payable [] memory){
        return lotteryPlayers;
    }

    function refund()public managerLimit{
        require(lotteryPlayers.length != 0);
        require(now>=drawEndTime);
        uint lenLotteryPlayers = lotteryPlayers.length;
        for(uint i = 0; i<lenLotteryPlayers;i++){
            lotteryPlayers[i].transfer(lotteryBet);
        }
        roundNum++;
        drawStartTime+=1 days;
        drawEndTime+=1 days;
        delete lotteryPlayers;

    }
    function getPlayersNum() public view returns(uint){
        return lotteryPlayers.length;
    }

}