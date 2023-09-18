pragma solidity ^0.4.18;
pragma experimental ABIEncoderV2;

interface token {
    function transfer(address receiver, uint amount) external;
    // function balanceOf() external;
}

contract Guess {
    uint80 constant None = uint80(0);

    uint public rounds; 
    uint public totalReward;
    address public owner;
    token public tokenAddress;

    struct game {
        bool live;
        uint anwser;
        mapping(address => bet) betinfo;
        address[] bettors;
        address[] winners;
        uint winAmount;
    }

    struct bet {
        address bettor;
        // big = true, small = false
        bool betted;
        uint choice;
        // bool bigOrSmall;
        // uint amount; 
    }

    struct result {
        address bettor;
        bool win;
        uint amount;
    }
    event Debug(string message);
    event DebugWithBytes(string message, bytes b);
    event DebugWithBool(string message, bool b);
    event DebugWithInt(string message, uint b);
    event DebugWithAddresses(string message, address[] b);

    mapping(uint => game) public gameNumber;
    
    constructor(
        address addressOfToken
    ) public {
        owner = msg.sender;
        rounds = 0;
        tokenAddress = token(addressOfToken);
        gameNumber[rounds].live = true;
    }

    // function() public payable{
    //     require()
    // }
    function tokenFallback(address _from, uint _value, bytes _data) public {
        emit Debug("received from tokenFallback");
        require(_value == 100 ether, "Incorret amount of token");
        emit Debug("value validated");
        if (!gameNumber[rounds].live) {
            // start a new game
            rounds ++;

            // bet[] memory b;
            // address[] memory adr;
            gameNumber[rounds].live = true;
        }
        emit DebugWithBytes("data is ", _data);
        // emit DebugWithBytes1("data is ", _data[0]);
        bet memory thisBet;
        // string memory small = "0x00";
        // bytes memory smallAsBytes = bytes(small);

        // string memory big = "0x01";
        // bytes memory bigAsBytes = bytes(big);

        string memory vote1 = "0x01";
        string memory vote2 = "0x02";
        string memory vote3 = "0x03";
        string memory vote4 = "0x04";
        string memory vote5 = "0x05";
        string memory vote6 = "0x06";

        // emit DebugWithBytes("small is ", smallAsBytes);
        // emit DebugWithBytes("big is ", bigAsBytes);

        if (keccak256(_data) == keccak256(bytes(vote1))) {
            thisBet = bet(_from, true, 1);
        } else if (keccak256(_data) == keccak256(bytes(vote2))) {
            thisBet = bet(_from, true, 2);
        } else if (keccak256(_data) == keccak256(bytes(vote3))) {
            thisBet = bet(_from, true, 3);
        } else if (keccak256(_data) == keccak256(bytes(vote4))) {
            thisBet = bet(_from, true, 4);
        } else if (keccak256(_data) == keccak256(bytes(vote5))) {
            thisBet = bet(_from, true, 5);
        } else if (keccak256(_data) == keccak256(bytes(vote6))) {
            thisBet = bet(_from, true, 6);
        } else {
            emit Debug("Invalid vote");
            revert("Invalid vote by revert");
        }

        // if (keccak256(_data) == keccak256(smallAsBytes)) {
        //     emit Debug("Voted small");
        //     thisBet = bet(_from, true, false);
        // } else if (keccak256(_data) == keccak256(bigAsBytes)) {
        //     emit Debug("Voted big");
        //     thisBet = bet(_from, true, true);
        // } else {
        //     emit Debug("Invalid vote");
        //     revert("Invalid vote by revert");
        // }

        require(!gameNumber[rounds].betinfo[_from].betted, "User already voted");
        totalReward += _value;
        gameNumber[rounds].betinfo[_from] = thisBet;
        gameNumber[rounds].bettors.push(_from);
        emit DebugWithBool("generate thisBet -- good", gameNumber[rounds].betinfo[_from].betted);
    }

    function settle() public returns (bool success) {
        // require(msg.sender == owner, "Not the owner");
        require(gameNumber[rounds].live, "There is no live game");
        require(gameNumber[rounds].bettors.length >= 2, "Not enough paticipants");

        uint random = uint(keccak256(block.timestamp))%6 +1;
        gameNumber[rounds].anwser = random;
        gameNumber[rounds].live = false;

        emit DebugWithInt("Generated random", gameNumber[rounds].anwser);

        uint winnerCount = 0;
        for (uint i = 0; i < gameNumber[rounds].bettors.length; i++) {
            address bettor = gameNumber[rounds].bettors[i];
            // if ((random >= 4 && gameNumber[rounds].betinfo[bettor].bigOrSmall) ||
            //     (random <= 3 && !gameNumber[rounds].betinfo[bettor].bigOrSmall)){
            //     winnerCount ++;
            // }
            if (random == gameNumber[rounds].betinfo[bettor].choice) winnerCount ++;
        }

        emit DebugWithInt("Winner counts", winnerCount);

        if (winnerCount == 0) return true;
        else {
            uint eachWinnerAmount = totalReward / winnerCount;
            gameNumber[rounds].winAmount = eachWinnerAmount;
            emit DebugWithInt("Win amount", eachWinnerAmount);
            for (uint j = 0; j < gameNumber[rounds].bettors.length; j++) {
                address bettor2 = gameNumber[rounds].bettors[j];
                // if ((random >= 4 && gameNumber[rounds].betinfo[bettor2].bigOrSmall) ||
                // (random <= 3 && !gameNumber[rounds].betinfo[bettor2].bigOrSmall)){
                if (random == gameNumber[rounds].betinfo[bettor2].choice) {
                    tokenAddress.transfer(bettor2, eachWinnerAmount);
                    totalReward -= eachWinnerAmount;
                    gameNumber[rounds].winners.push(bettor2);
                }
            }
        }
        emit DebugWithAddresses("winners are ", gameNumber[rounds].winners);
        return true;
    }

    function prizePool() public view returns (uint a) {
        return totalReward;
    }

    function getRounds() public view returns (uint r) {
        return rounds;
    }

    function lastBetOf(address adr) public view returns (uint) {
        return gameNumber[rounds].betinfo[adr].choice;
    }

    function bettorsOf(uint n) public view returns (address[] bettors) {
        return gameNumber[n].bettors;
    }

    function winnersOf(uint n) public view returns (address[] winners) {
        return gameNumber[n].winners;
    }

    function statusOf(uint n) public view returns (bool live){
        return gameNumber[n].live;
    }

    function answerOf(uint n) public view returns (uint a) {
        return gameNumber[n].anwser;
    }

    function winAmountOf(uint n) public view returns (uint a) {
        return gameNumber[n].winAmount;
    }
}