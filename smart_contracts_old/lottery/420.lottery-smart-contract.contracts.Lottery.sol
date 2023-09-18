// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

//smart1

contract Lottery {
    struct BetInfo{
        uint256 answerBlockNumber;
        address payable bettor; // 돈 건사람의 주소
        byte challenges;  //oxab bettor들이 보낸값

    }
    address payable public owner;
    uint256 private _pot;

    bool private mode =false; //test mode
    bytes32 public answerForTest;
    
    uint256 private _tail;
    uint256 private _head;
    mapping(uint256 => BetInfo) private _bets;
    
    uint256 constant internal BET_BLOCK_LIMIT =256;
    uint256 constant internal BET_BLOCK_INTERVAL =3;
    uint256 constant internal BET_AMOUNT= 5 * 10 ** 15;

    enum BlockStatus {checkable, NotRevealed, BlcokLimitPassed}
    enum BettingResult{Fail, Win, Draw}
    
    event BET(uint256 index , address bettor, uint256 amount,  byte challenge, uint256 answerBlock);
    event WIN(uint256 index, address bettor, uint amount ,byte challenges , byte answer, uint answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint amount ,byte challenges , byte answer, uint answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint amount ,byte challenges ,uint answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint amount ,byte challenges , uint answerBlockNumber);

    constructor() public{
        owner=msg.sender;
    }

    
    function getPot() public view returns(uint256 pot){
        return _pot;
    }

    function betAndDistribute(byte challenge) public payable returns (bool){
        bet(challenge);

        distribute();

        return true;
    }

    /**
     **@dev 유저는 0.005이더를 보내야하고, 배팅용 1byte 보낸다
     **이후 distribute 함수에서 처리
     */
    function bet(byte challenges) public payable returns (bool){
        //돈이 제대로 왔는지
        require(msg.value== BET_AMOUNT, "Not enough ETH");

        //큐에다가 bet정보 push
        require(pushBet(challenges),"Fail to add a new Bet");

        //emit event
        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        return true;
    }

    //정답을 확인할 수 없을때(블록이 아직 생성 안됨)까지 계속 돌림
    function distribute() public{
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;
        for(cur=_head; cur<_tail; cur++){
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            //잘될때

            if(currentBlockStatus==BlockStatus.checkable){
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult=isMatch(b.challenges,answerBlockHash);
                
                //if win bettor gets pot
                if(currentBettingResult ==BettingResult.Win){
                    transferAmount = transferAfterPayingFee(b.bettor, _pot+ BET_AMOUNT);
                    _pot =0;
                    emit WIN(cur, b.bettor, transferAmount , b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }
                
                //if fail bettor's money goes pot
                if(currentBettingResult ==BettingResult.Fail){
                    _pot += BET_AMOUNT;
                    emit FAIL(cur, b.bettor, 0 , b.challenges, answerBlockHash[0], b.answerBlockNumber);
                }

                //if draw refund
                if(currentBettingResult ==BettingResult.Draw){
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    emit DRAW(cur, b.bettor, transferAmount , b.challenges, b.answerBlockNumber);
                
                }
            }
            //마이닝 안될때
            if(currentBlockStatus==BlockStatus.NotRevealed){
                break;
            }
            //256 넘어 갔을 떄
            if(currentBlockStatus==BlockStatus.BlcokLimitPassed){
                //refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                emit DRAW(cur, b.bettor, transferAmount , b.challenges,  b.answerBlockNumber);
                
                //refund emit
            }

            popBet(cur);
        }
        _head =cur;

    }

    function transferAfterPayingFee(address payable addr, uint amount)  internal returns(uint256) {
        uint fee = 0;
        uint256 amountWithoutFee= amount -fee;

        addr.transfer(amountWithoutFee);


        owner.transfer(fee);



        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns(bool){
        answerForTest = answer;
        return true;

    }
    function getAnswerBlockHash (uint answerBlockNmber ) internal view returns (bytes32 ){
        return mode ? blockhash(answerBlockNmber) : answerForTest;
    }
    function isMatch(byte challenges, bytes32 answer) public pure returns(BettingResult ) {
        byte c1= challenges;
        byte c2= challenges;
        byte a1= answer[0];
        byte a2= answer[1];

        c1 = c1>>4;
        c1 = c1<<4;

        a1 = a1>>4;
        a1 = a1<<4;

        c2 = c2<<4;
        c2 = c2>>4;

        a2 = a2<<4;
        a2 = a2>>4;

        if(a1 ==c1 && a2 == c2){
            return BettingResult.Win;
        }

        if(a1 ==c1 || a2 == c2){
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number <BET_BLOCK_LIMIT + answerBlockNumber){
            return BlockStatus.checkable;
        }
        if(block.number <= answerBlockNumber){
            return BlockStatus.NotRevealed;
        }
        if(block.number >= answerBlockNumber+ BET_BLOCK_LIMIT){
            return BlockStatus.BlcokLimitPassed;
        }

        return BlockStatus.BlcokLimitPassed;
    }

    function getBetInfo(uint index) public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
        BetInfo memory b =_bets[index];
        answerBlockNumber= b.answerBlockNumber;
        bettor =b.bettor;
        challenges = b.challenges;

    }
    function pushBet(byte challenges) payable public returns (bool){
         BetInfo memory b;
         b.bettor =msg.sender;
         b.answerBlockNumber =block.number + BET_BLOCK_INTERVAL;
         b.challenges = challenges;

         _bets[_tail] =b;
         _tail++;

         return true;
    }

    function popBet(uint256 index) public returns (bool){
        delete _bets[index];
        return true;
    }
}