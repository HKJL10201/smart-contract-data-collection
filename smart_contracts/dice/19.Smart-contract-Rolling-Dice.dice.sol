// SPDX-License-Identifier: UNDEFINED

pragma solidity >=0.7.0 <0.9.0;


contract Dice {
    mapping(address => uint256) balance;
    mapping(address => bool) registered;
    address[] private players;
    bool private result;
    bool private rolldone;
    uint256 private val;
    uint256 private diceval;
    uint256 private nonce;
    bool private finished;
    uint32 constant private TIMEOUT = 5 minutes; // after TIMEOUT results the game can be finished
    uint private startTime;
    error Unauthorized();

    
    function timeForTimerToEnd() public view returns (uint) {
        if (startTime != 0) {
            uint remainingTime = startTime + TIMEOUT - block.timestamp;
            if (remainingTime < 0) {
                return 0;
            } else {
                return remainingTime;
            }
        }
        return TIMEOUT;
    }
    function register() public payable{
        require(msg.value >3 ether);
        require(players.length<=1,"There is already 2 players! You can enter game later");
        require(registered[msg.sender]==false,"You have already registered!");
        balance[msg.sender] += msg.value;
        players.push(msg.sender);
        registered[msg.sender]=true;
    }
    function deposit() public payable {
        require(registered[msg.sender]==true,"You need to register first");
        balance[msg.sender] += msg.value ;
    } 
    function withdraw() public {
        if (finished==false && rolldone==false){
            uint256 b = balance[msg.sender];
            balance[msg.sender] = 0;
            payable(msg.sender).transfer(b);
        }else if(finished==true && rolldone==true){
            uint256 a = balance[players[0]];
            balance[players[0]] = 0;
            payable(players[0]).transfer(a);
            uint256 b = balance[players[1]];
            balance[players[1]] = 0;
            payable(players[1]).transfer(b);
            reset();
        }else{
            revert Unauthorized();
        }
    }

    function roll() internal returns (uint) {
        startTime = block.timestamp;
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 6;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
    }

    function viewBalance() public view returns(uint256){
        return balance[msg.sender];
    }
    modifier canComputeResult() {
        require(
            (block.timestamp > startTime + TIMEOUT) ||
            (rolldone==true)
        );
        _;
    }
    function finishgame() public canComputeResult returns(string memory){
        address payable address1 = payable(players[0]);
        address payable address2 = payable(players[1]);
        updateBalances(address1,address2);
        finished=true;
        return result ? "Player1 won" : "Player2 won";
    }
    function reset() private{
        rolldone=false;
        finished=false;
        startTime=0;
        registered[players[0]]=false;
        registered[players[1]]=false;
        players.pop();
        players.pop();
    }

    function startRolling() public payable{
        require(balance[players[0]] > 3 , "Player 1, Not enough balance to play !");
        require(balance[players[1]] > 3 , "Player 2, Not enough balance to play !");
        require(rolldone==false,"Dice already rolled! Please click viewresult!");
        diceval=roll();
        rolldone=true;
        if (diceval <4 ){
            result = true;
            val=diceval;
        }else if (diceval>3){
            result = false;
            val=diceval-3;
        }
    }
    function withdrawReward() public {
        require(finished==true,"you need to finish the game to receive the reward");
        uint256 a = balance[players[0]];
        balance[players[0]] = 0;
        payable(players[0]).transfer(a);
        uint256 b = balance[players[1]];
        balance[players[1]] = 0;
        payable(players[1]).transfer(b);
        reset();
    }
    function updateBalances(address payable address1, address payable address2) private {
        if (result==true){
            balance[address1] += val*1000000000000000000;
            balance[address2] -= val*1000000000000000000;
        }else if (result ==false){
            balance[address2] += val*1000000000000000000;
            balance[address1] -= val*1000000000000000000;
        }
    }
}