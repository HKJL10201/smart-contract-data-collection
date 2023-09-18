// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

contract Lottery{

    struct BetInfo {
        uint256 answerBlockNumber;  // 맞추려는 정답 블록의 해시번호
        address payable bettor; // 베팅자의 지갑주소, 거래 관련이라 payable
        bytes1 challenges; // 베터가 제시한 문자 ex) 0xab
    }

    uint256 private _tail; // _bets로 값이 들어오면 _tail이 증가
    uint256 private _head; // _head 값에서부터 값을 검증
    mapping (uint256 => BetInfo) private _bets; // queue
    
    address payable public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3; // +3번 블락에 배팅(1 -> 4번)
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; // 고정된 베팅값(0.005eth)

    uint256 private _pot; // 팟머니 저장할 곳
    bool private mode = false;  // false: test answer for testing, true: real block hash
    bytes32 public answerForTest;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    constructor() public {
        owner = msg.sender;
    }

    // 팟에 대한 getter
    // 스마트 컨트랙트의 변수 조회를 위한 view 제어자 
    function getPot() public view returns (uint256 pot){
        return _pot;
    }
    
    /**
    * @dev 베팅과 정답체크를 한다. 유저는 0.005ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다
    * 큐에 저장된 베팅정보는 이후 distributre 함수에서 해결된다. 
    * @param challenges 유저가 베팅하는 글자
    * @return 함수가 잘 수행되었는지 확인하는 bool 값
    */
    function betAndDistribute(bytes1 challenges) public payable returns (bool result){
        bet(challenges);
        distribute();
        return true;
    }
    
    /**
    * @dev 베팅을 한다. 유저는 0.005ETH를 보내야 하고, 베팅용 1 byte 글자를 보낸다
    * 큐에 저장된 베팅정보는 이후 distributre 함수에서 해결된다. 
    * @param challenges 유저가 베팅하는 글자
    * @return 함수가 잘 수행되었는지 확인하는 bool 값
    */
    function bet(bytes1 challenges) public payable returns(bool result){
        // 돈이 제대로 들어왔는지 체크
        require(msg.value == BET_AMOUNT, "Not enough ETH");
        // queue에 bet 정보 push
        require(pushBet(challenges),"Fail to add a new Bet Info");
        // event 로그 찍기
        emit BET(_tail - 1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        return true;
    }

    /**
    * @dev 베팅 결과값을 확인하고 팟머니를 분배한다.
    * 정답실패: 팟머니 축적, 정답 맞추미 팟머니 획득, 한글자 맞춤/정답 확인 불가 : 배팅 금액만 획득 
    */
    // distribute
    function distribute() public {
        // head 3 4 5 6 7 ... tail
        uint256 cur;
        uint256 transferAmount; // 전송한 금액

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur = _head; cur < _tail; cur++){
            b = _bets[cur]; // 베팅 정보 불러오기
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            
            // 블럭 해시 확인 불가 1. 블럭이 아직 마이닝 안됐을때, 2. 블럭 제한을 넘어갔을때
            // checkable : 블럭 번호가 정답 블럭 번호보다 크고, 블럭 제한 번호+ 정답 블럭 번호보다 작을 때
            if(currentBlockStatus == BlockStatus.Checkable){
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash); 
                // if win, bettor gets pot
                if(currentBettingResult == BettingResult.Win){
                    // transfer pot
                    transferAmount = trnasferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    
                    // pot = 0
                    _pot = 0;
                    
                    // emit WIN
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if fail, bettor's money goes to pot
                if(currentBettingResult == BettingResult.Fail){
                    // pot = pot + BET_AMOUNT
                    _pot = _pot + BET_AMOUNT;

                    // emit FAIL
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                // if draw, refund bettor's money
                if(currentBettingResult == BettingResult.Draw){
                    // transfer only BET_AMOUNT
                    transferAmount = trnasferAfterPayingFee(b.bettor, BET_AMOUNT);

                    // emit DRAW
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                
            } 
            // not revealed(1번)
            if(currentBlockStatus == BlockStatus.NotRevealed){
                break;
            }
            // block limit passed(2번)
            if(currentBlockStatus == BlockStatus.BlockLimitPassed){
                // refund
                transferAmount = trnasferAfterPayingFee(b.bettor, BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }
            popBet(cur);
        }
        _head = cur;
    }
    
    function trnasferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256){
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);
        // transfer to owner
        owner.transfer(fee);

        // 이더 전송 방법 : call, send, transfer
        // transfer를 가장 많이 사용하며 가장 안전한 방법. 
        
        return amountWithoutFee;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus){
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

    function setAnswerForTest(bytes32 answer) public returns (bool result){
        require(msg.sender == owner, "only onwer can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns(bytes32 answer){
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /**
    * @dev 베팅글자와 정답을 확인한다.
    * @param challenges 베팅 글자
    * @param answer 블럭해시
    * @return 정답결과
    */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns(BettingResult){
        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // get first number
        c1 = c1>>4; // 0xab -> 0x0a
        c1 = c1<<4; // 0x0a -> 0xa0

        a1 = a1>>4; 
        a1 = a1<<4; 

        // get second number
        c2 = c2<<4; // 0xab -> 0xb0
        c2 = c2>>4; // 0x0a -> 0x0b

        a2 = a2<<4; 
        a2 = a2>>4; 

        if(a1 == c1 && a2 == c2){
            return BettingResult.Win;
        }
        if(a1 == c1 || a2 == c2){
            return BettingResult.Draw;
        }
        
        return BettingResult.Fail;
        
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges){
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) public returns (bool){
        BetInfo memory b;
        b.bettor = msg.sender;
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // block.number : 현재 트랙제션의 블락 넘버를 가져옴
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true;
    }

    function popBet(uint256 index) public returns (bool){
        // map에 있는 값을 초기화하게 되면 가스를 돌려받게 된다. -> 필요하지 않은 값은 delete 해 주는 게 좋다.
        delete _bets[index];
        return true;  
    }
}