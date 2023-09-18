// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        bytes1 challenges;
    }

    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public owner;
    uint256 private _pot;
    bool private mode = false;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    uint256 constant internal BET_BLOCK_INTERVAL = 2;

    bytes32 answerForTest = 0xab5119e99b5dd50aeea88b5f4170dda9a547da4a95c211ae712114835c3a81d4;

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    constructor() public {
        owner = payable(msg.sender);
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        addr.transfer(amountWithoutFee);
        owner.transfer(fee);

        return amountWithoutFee;


    }

    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();
        
        return true;
    }


    //bet function
    function bet(bytes1 challenges) public payable returns (bool result) {
        //check the eth
        require(msg.value == BET_AMOUNT, "Not enough money ETH");
        require(pushBet(challenges), "Fail to add a new Bet info");
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number+BET_BLOCK_INTERVAL);
        return true;
    }

    function distribute() public {
        uint256 cur;
        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;
        uint256 transferAmount;
        for(cur=_head; cur<_tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            //checkable
            if(currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                if(currentBettingResult == BettingResult.Win) {
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    _pot = 0;
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                if(currentBettingResult == BettingResult.Fail) {
                    _pot += BET_AMOUNT;
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                if(currentBettingResult == BettingResult.Draw) {
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    emit FAIL(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }

            //not revealed
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            // block limit passed
            if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                //refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);

            }
            popBet(cur);
        }
        _head = cur;
    }

    function isMatch(bytes1 challenges, bytes32 answer) public pure returns(BettingResult){
        bytes1 c1 = challenges;
        bytes1 c2 = challenges;
        bytes1 a1 = answer[0];
        bytes1 a2 = answer[1];

        c1 = c1 >> 4;
        c1 = c1 << 4;

        a1 = a1 >> 4;
        a1 = a1 << 4;

        c2 = c2 << 4;
        c2 = c2 >> 4;

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        if(a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
        
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }
        if(block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }
        if(block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) public returns (bool) {
        BetInfo memory b;
        b.bettor = payable(msg.sender);
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;
        _bets[_tail] = b;
        _tail++;

        return true;
    }

    function popBet(uint256 index) public returns (bool) {
        delete _bets[index];
        return true;
    }
}
