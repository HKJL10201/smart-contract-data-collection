pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    struct BetInfo{
        uint256 answerBlockNumber;
        address bettor;
        byte challenges; //0xab (1byte 정답)
    }

    address public owner;
    //팟머니 저장
    uint256 private _pot;
    uint256 private _tail; // _bets로 데이터가 들어오면 _tail을 늘린다.
    uint256 private _head; // 결과값 확인할 떄는 0번(_head)부터 차례대로 확인.

    //베팅액
    uint256 constant internal BET_AMOUNT = 5 * 10 **15;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BLOCK_LIMIT = 256;
    //베팅 정보들을 저장할 맵
    mapping (uint256 => BetInfo) private _bets;
    //_bets를 관리할 큐를 위한 변수들 : _tail, _head

    bool private mode = false; // false : use answer for test mode.  true : use real block hash
    bytes32 public answerForTest;

    // enum 배열이므로 실제로는 정수 0, 1, 2 를 리턴한다.
    enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed }
    enum BettingResult {Fail, Win, Draw }

    event BET(uint256 index, address indexed bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, byte challenges, byte answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, byte challenges, uint256 answerBlockNumber);
    constructor() public {
        owner = msg.sender;
    }

    function getPot() public view returns (uint256 value){
        return _pot;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
        //mapping의 경우 인덱스가 3번까지 있는데 5번이 입력될 시 0을 리턴함.
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }


    /**
    @dev 베팅을 한다. 유저는 0.005 이더를 보내야 하고, 베팅용 1바이트 글자를 보낸다. 베팅 정보를 큐에 저장하고, 이벤트를 발생시킨다.
    큐에 저장된 베팅정보들은 이후 distribute 함수에서 해결한다.
    @param  challenges 유저가 베팅하는 글자.
    @return 함수가 잘 수행되었는지 확인하기 위한 bool 값
     */
    function bet(byte challenges) public payable returns (bool result) {
        // Check the proper amount of ether is sent
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // Push bet to the queue. 큐에 베팅정보를 저장한다.
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // Emit event
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    function pushBet(byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender; // 20 byte
        //block.number = 현재 트랜잭션이 들어간 블록의 번호.
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte(uint256기 때문에) = 20000 gas.
        b.challenges = challenges;  //byte.   b.bettor(=20바이트)와 합쳐 20000gas 사용한다고 어림잡아 계산

        // 메모리에 저장된 b(20+32+1 byte)의 데이터가 실제 블록체인에 저장되어서 가스 발생.
        _bets[_tail] = b;
        //tail값을 조건문으로 검사한다거나 문제생길 것 같으면 safemath로 확인해줘야겠지만. 여기선 넘어감.
        _tail++; // 32byte. 값 변화(초기 0 -> 1) = 20000 가스.  기존의 값 변화 (1 -> 2, 2-> 3 등...) 5000 가스.

        return true;
    }

    function popBet(uint256 index) internal returns (bool) {
        /**
        pop시 매핑이기 때문에 리스트에서 삭제하기보다는 단순하게 값을 초기화시키는 식으로 진행.
        맵에 있는 값을 delete하게 되면 가스를 돌려받는다. status database에 있는 값을 없애기 때문에. 그래서 사용하지 않는 값은 늘 삭제해주는 것이 좋다
        */
        delete _bets[index];
        return true;
    }

    /**
    베팅, 정답 체크를 한번에 하는 함수. 현재 베팅함수와 정답확인 함수가 따로 나눠져 있어서, 유저들이 베팅을 하고 정답확인을 운영자들이 해줘야 하는데 유저들이 정답 확인하면서 남의 정답도 같이 확인함. 그래서 베팅, 정답확인, 분배가 동시에 일어나게 하는 함수 작성이 필요. 추후 웹 프론트에서 사용할 예정.
    @dev 베팅과 정답체크를 한다.
    @param challenges 유저가 베팅하는 문자열
    @return 함수가 잘 수행되었는지 확인하기 위한 bool 값
     */
    function betAndDistribute(byte challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();

        return true;
    }

    /**
    @dev 베팅 결과값을 확인하고 결과값에 따라 베팅액과 팟머니를 처리
    정답실패 : 베팅금을 팟머니에 축적. 정답 맞춤 : 팟머니를 정답자에게 전송. 한글자 맞춤 or 정답확인불가 : 베팅 금액만 돌려줌.
    */
    function distribute() public {
        //head부터 tail까지 모두 도는 루프.
        uint256 cur;
        uint256 transferAmount; // 정답 맞춘 유저에게 보낼 팟머니.

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;
        for(cur=_head; cur<_tail ; cur ++){
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            //블록넘버 확인 가능한 상태인지 확인. Checkable =  1. 블록넘버 확인 가능함 = 정답 확인.
            if(currentBlockStatus == BlockStatus.Checkable){
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                //if win, bettor gets pot
                if (currentBettingResult == BettingResult.Win) {
                    //transfer pot. 수수료를 뗀 후 팟머니 전송.
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    //pot = 0
                    _pot = 0;
                    //emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                //if fail, bettor's pot goes pot
                if (currentBettingResult == BettingResult.Fail) {
                    //pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    //emit Fail
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                //if draw, refund bettor's money
                if (currentBettingResult == BettingResult.Draw) {
                //transfer only BET_AMOUNT(refund)
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                //emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
            }
            //블록넘버 확인 가능한 상태인지 확인. 1. Not Revealed : 아직 마이닝 되지 않았다.   2
            if(currentBlockStatus == BlockStatus.NotRevealed){
                break;
            }
            //블록넘버 확인 가능한 상태인지 확인 2. Limit block passed : 너무 오래전에 마이닝된 블록(256번째 전 블록). 3
            if(currentBlockStatus == BlockStatus.BlockLimitPassed){
                //refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                //emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);
        }
        _head = cur;
    }

    /**
    @dev 베팅 글자와 정답을 비교해 확인한다.
    @param challenges 베팅 글자
    @param answer 정답(블록해시)
    @return 정답결과
     */
    function isMatch(byte challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges = 0xab,  answer = 0xab....ff 라는 32바이트 글자. 첫번째 글자부터 뽑아 서로 비교한다. 
        byte c1 = challenges;
        byte c2 = challenges;
        //0번 해시을 가져옴.  0xab....ff 에서 (a에 해당).
        byte a1 = answer[0];
        byte a2 = answer[0];

        // Get first number
        c1 = c1 >> 4; // 0xab -> 0x0a
        c1 = c1 << 4; // 0x0a -> 0xa0

        a1 = a1 >> 4;
        a1 = a1 << 4;

        //Get Second number
        c2 = c2 << 4; // 0xab -> 0xb0
        c2 = c2 >> 4; // 0xb0 -> 0x0b

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if(a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        if(a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns(BlockStatus){
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber){
            return BlockStatus.Checkable;
        }
        if(block.number <= answerBlockNumber){
            return BlockStatus.NotRevealed;
        }
        if(block.number >= answerBlockNumber + BLOCK_LIMIT){
            return BlockStatus.BlockLimitPassed;
        }
        return BlockStatus.BlockLimitPassed;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        //mode가 true라면 blockhash(answerBlockNumber),  false라면(테스트모드) answerForTest 리턴
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }
    function setAnswerForTest(bytes32 answer) public returns (bool result){
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    //일정부분을 수수료로 컨트랙트 주인에게 전송. 수수료 떼진 베팅금을 리턴.
    function transferAfterPayingFee(address addr, uint256 amount) internal returns (uint256) {
        // fee = amount / 100;
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;
        // transfer to addr
        addr.transfer(amountWithoutFee);
        // transfer to owner
        owner.transfer(fee);
        return amountWithoutFee;
    }
}