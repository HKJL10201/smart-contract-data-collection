pragma solidity >=0.4.21 <0.6.0;

contract Lottery {

    struct BetInfo {
        uint256 answerBlockNumber;
        address payable betPerson;
        byte challenges;
    }

    uint256 private head;
    uint256 private tail;
    mapping(uint256=>BetInfo) private betInfoMap;

    address public owner;
    bool private mode; // false : test mode, true : real use
    bytes32 public answerForTest;

    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    uint256 constant internal BLOCK_INTERVAL = 3;
    uint256 constant internal BLOCK_LIMIT = 256;

    uint256 private pot;

    enum BlockStatus {PASSED_BLOCK, ON_THE_BLOCK, OVER_THE_BLOCK}
    enum BettingResult {WIN, LOSE, DRAW}

    event BET(uint256 index, address betPerson, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address betPerson, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event LOSE(uint256 index, address betPerson, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address betPerson, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address betPerson, uint256 amount, byte challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns (uint256 value    ) {
        return pot;
    }

    /**
     * @dev 베팅을 한다. 유저는 0.005 ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다.
     * 큐에 저장된 베팅 정보는 이후 distribute 함수에서 해결된다.
     * @param challenges 유저가 베팅하는 글자
     * @return 함수가 잘 수행되었는지 확인해는 bool 값
     */
    function bet(byte challenges) public payable returns (bool result) {
        require(msg.value == BET_AMOUNT, 'not enough ETH');
        require(pushBet(challenges), 'cant pushBet');
        emit BET(tail-1, msg.sender, msg.value, challenges, block.number+BLOCK_INTERVAL);

        return true;
    }

    /**distribute bet ETH by result */
    function distribute() public {

        uint256 flag;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentStatus;
        BettingResult currentBettingResult;

        for(flag=head;flag<tail;flag++){

            b = betInfoMap[flag];
            currentStatus = getBlockStatus(b.answerBlockNumber);

            if(currentStatus == BlockStatus.PASSED_BLOCK) {

                //refund BET_AMOUNT
                transferAmount = transferWithoutFee(b.betPerson, BET_AMOUNT);
                emit REFUND(flag, b.betPerson, transferAmount, b.challenges, b.answerBlockNumber);

            }
            if(currentStatus == BlockStatus.OVER_THE_BLOCK) {

                break;

            }
            if(currentStatus == BlockStatus.ON_THE_BLOCK) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                
                if (currentBettingResult == BettingResult.WIN) {

                    // transfer pot to better
                    transferAmount = transferWithoutFee(b.betPerson, pot + BET_AMOUNT);
                    //  pot = 0
                    pot = 0;
                    // emit Win event
                    emit WIN(flag, b.betPerson, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                } else if (currentBettingResult == BettingResult.LOSE) {

                    // pot += BET_AMOUNT
                    pot += BET_AMOUNT;
                    //emit LOSE event
                    emit LOSE(flag, b.betPerson, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                } else if (currentBettingResult == BettingResult.DRAW) {

                    // transfer only BET_AMOUNT to better
                    transferAmount = transferWithoutFee(b.betPerson, BET_AMOUNT);
                    // emit DRAW event
                    emit DRAW(flag, b.betPerson, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }
            }
            popBet(flag);
        }
        head = flag;
    }

    /** take fee from transfer amount */
    function transferWithoutFee(address payable addr, uint256 amount) internal returns (uint256) {
        
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        msg.sender.transfer(fee);

        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 setAnswer) public returns (bool result) {
        answerForTest = setAnswer;
        return true;
    }

    //hash값은 random하기에 테스트를 위해서 임의의 해시값을 이용하여 테스트하는 모드를 구현.
    function getAnswerBlockHash(uint256 answerBlockHash) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockHash) : answerForTest;
    }

    function betAndDistribute(byte challenges) public payable returns (bool result){
        bet(challenges);
        distribute();
        return true;
    }

    /** check between challenge and hashnumber*/
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {

        byte c1 = challenges;
        byte c2 = challenges;

        byte a1 = answer[0];
        byte a2 = answer[0];

        // Get first number
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get Second number
        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;    

        if(a1 == c1 && a2 == c2) {
            return BettingResult.WIN;
        }
        
        if (a1 == c1 || a2 == c2) {
            return BettingResult.DRAW;
        }
        
        return BettingResult.LOSE;
    }

    /**
    PASSED_BLOCK => refund
    ON_THE_BLOCK => bet
    OVER_THE_BLOCK=> cancel
     */
    function getBlockStatus(uint256 answerBlockNumber) public view returns (BlockStatus){
        if(block.number > answerBlockNumber && block.number  <  BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.ON_THE_BLOCK;
        }

        if(block.number <= answerBlockNumber) {
            return BlockStatus.OVER_THE_BLOCK;
        }

        if(block.number >= answerBlockNumber + BLOCK_LIMIT) {
            return BlockStatus.PASSED_BLOCK;
        }

        return BlockStatus.PASSED_BLOCK;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address betPerson, byte challenges) {
        BetInfo memory b = betInfoMap[index];
        answerBlockNumber = b.answerBlockNumber;
        betPerson = b.betPerson;
        challenges = b.challenges;
    }

    // start bet queue
    function pushBet(byte challenges) internal returns (bool){
        BetInfo memory b;

        b.answerBlockNumber = block.number + BLOCK_INTERVAL;
        b.betPerson = msg.sender;
        b.challenges = challenges;

        betInfoMap[tail] = b;
        tail++;

        return true;
    }

    // end bet queue
    function popBet(uint256 index) public returns (bool){
        delete betInfoMap[index];
        
        return true;   
    }
}