// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery{

    // answer Block
    
    struct BetInfo {
        uint256 answerBlockNumber;
        // payable ������� transfer ����
        address payable bettor;
        bytes1 challenges; //0xab
    }

    // QUEUE
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    // ??
    address payable public owner;
    
    // BLOCK HASH�� Ȯ���� �� �ִ� ���� 256
    uint256 constant internal BLOCK_LIMIT = 256;

    // 3�� ����� ������ �ϰ� �Ǹ� 6�� ���� ������ �ϰ� �ȴ�
    uint256 constant internal BET_BLOCK_INTERVAL = 3;

    // �����ϴ� �ݾ� 0.005ETH // 1ETH = 10 ** 18
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;

    // pot money ??
    uint256 private _pot;

    bool private mode = false; // false : test mode(use answer for test), true : real mode(use real block hash)
    bytes32 public answerForTest;


    // BlockStatus Enum
    enum BlockStatus { Checkable, NotRevealed, BlockLimitPassed}

    // ��Ī ��� Enum
    enum BettingResult { Win, Fail, Draw}

    // EVENT
    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber); // emit ��ü 375gas + �Ķ���� �ϳ� �� 375 gas + �Ķ���� ���� �ɶ� byte�� 8gas => 4~5000 gas 
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumber);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);

    
    // Constructor
    constructor() public {
        owner = msg.sender;
    }



    /* 
    view?: function ���� �������� ������ ������ ���� �Ұ���
    pure :?function ���� �������� ���� ���ϰ�, ���浵 �Ұ���
    view �� pure �Ѵ� ��� ���Ҷ�:?function ���� �������� �о, ������ �ؾ���.
    */

    function getPot() public view returns (uint256 pot){
        return _pot;
    }


    /*
    * @dev ���ð� ����üũ�� �Ѵ�. ������ 0.005ETH�� �������ϰ�, ���ÿ� 1 byte ���ڸ� ������.
    * ť�� ����� ���� ������ ���� distribute �Լ����� �ذ�ȴ�.
    * @param challenges ������ �����ϴ� ����
    * @return �Լ��� �� ����Ǿ����� Ȯ���ϴ� bool ��
    */

    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);
        distribute();
        return true;
    }

    //Bet

    /*
    * @dev ������ �Ѵ�. ������ 0.005ETH�� �������ϰ�, ���ÿ� 1 byte ���ڸ� ������.
    * ť�� ����� ���� ������ ���� distribute �Լ����� �ذ�ȴ�.
    * @param challenges ������ �����ϴ� ����
    * @return �Լ��� �� ����Ǿ����� Ȯ���ϴ� bool ��
    */
    
    function bet(bytes1 challenges) public payable returns (bool result) {

        // Check the proper ether is sent 
        // Not enough ETH
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        // Push bet to the queue
        require(pushBet(challenges), "Fail to add a new Bet Info");

        // Emit event
        emit BET(_tail -1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);
        return true;

    }
    

    //Distribute ����

    /*
    * @dev ���� ������� Ȯ���ϰ� �̸Ӵϸ� �й��Ѵ�.
    * ���� ���� : �̸Ӵ� ����
    * ���� ���� : �̸Ӵ� ȹ��
    * �ѱ��ڸ��� or ���� Ȯ�� �Ұ� : ���� �ݾ׸� ȹ��
    */

    function distribute() public {
        // head 3 4 5 ... 11 12 tail
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for (cur = _head; cur < _tail; cur++) {

            // BetInfo �ҷ�����
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);

            // ���� BlockStatus Ȯ�� 3����
            // Checkable : (block.number > answerBlockNumber) && (block.number < BLOCK_LIMIT + answerBlockNumber) (���� ��Ϻ��� 256 �������� Ȯ���� �� �ִ� �̰Թ���������?)
            if (currentBlockStatus == BlockStatus.Checkable) {

                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);

                currentBettingResult = isMatch(b.challenges,answerBlockHash);

                // Betting ����� ���� 3���� 
                // if win , bettor�� pot money ������
                if (currentBettingResult == BettingResult.Win) {
                    // transfer pot
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    // pot = 0
                    _pot = 0;
                    // ���⼭ transfer�ϰ� _pot=0�� �ߴµ�, call�̳� send�� ��쿣 ���� _pot�� �ӽú����� �����س��� �ӽú����� ���� ������ �Ѵ��� �����ϴ°� ����

                    // emit Win event
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }

                // if fail, bettor�� ���� pot���� ��
                if (currentBettingResult == BettingResult.Fail) {
                    // pot = pot + BET_AMOUNT
                    _pot += BET_AMOUNT;
                    // emit Fail event
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);

                }

                // if draw (�ѱ��ڸ� ���� ���), refund bettor's money
                if (currentBettingResult == BettingResult.Draw) {
                    // transfer only BET_AMOUNT
                    transferAmount = transferAfterPayingFee(b.bettor,BET_AMOUNT);
                    // emit Draw event
                    emit DRAW(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);


                }
            }
            
            // block�� mining ���� ���� ����(not revealed) : block.number <= answerBlockNumber // ��ȣ�� ���� ���� : ��������� �����̹Ƿ� block.number Ȯ�� �Ұ�
            if (currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }

            // block limit passed (��������) : block.number >= BLOCK_LIMIT + answerBlockNumber
            if (currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor,BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, transferAmount, b.challenges, b.answerBlockNumber);
            }

            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        // uint256 fee = amount / 100;
        uint256 fee = 0; // simple�ϰ� �ϱ� ���� 0
        uint256 amountWithoutFee = amount - fee;

        // transfer to addr
        addr.transfer(amountWithoutFee);

        // transfer to owner
        owner.transfer(fee);

        return amountWithoutFee;
    }

    function setAnswerforTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer for test mode");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }

    /*
    * @dev ���ñ��ڿ� ������ Ȯ���Ѵ�.
    * @param challenges ���� ����
    * @param answer ��� �ؽ�
    * @return ������
    */
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {

        // challenges 0xab = 1010 1011
        // answer 0xab......ff 32bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];

        // Get first number // challenges
        c1 = c1 >> 4; // 1010 1011 -> 0000 1010 // c1 = 0x0a
        c1 = c1 << 4; // 0000 1010 -> 1010 0000 // c1 = 0xa0

        // Get first number // answer[0]
        a1 = a1 >> 4;
        a1 = a1 << 4;

        // Get second number // challenges
        c2 = c2 << 4; // 1010 1011 -> 1011 0000 // c2 = 0xb0
        c2 = c2 >> 4; // 1011 0000 -> 0000 1011 // c2 = 0x0b

        // Get second number // answer[0]
        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        else if (a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        else return BettingResult.Fail;
    }
        // Block ����
        function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
            if (block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
                return BlockStatus.Checkable;
            }
            else if (block.number <= answerBlockNumber) {
                return BlockStatus.NotRevealed;
            }
            else if (block.number >= BLOCK_LIMIT + answerBlockNumber) {
                return BlockStatus.BlockLimitPassed;
            }
            else return BlockStatus.BlockLimitPassed;
        }



    // _bets ? ?? ?? ???? getter
    function getBetInfo(uint256 index) public view returns(uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    // QUEUE push
    function pushBet(bytes1 challenges) internal returns (bool) {
        BetInfo memory b;

        b.bettor = msg.sender; // 20 byte

        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte -> 20000 gas
        b.challenges = challenges; // byte -> ���� msg.sender�� 20byte + �ϸ� 20000gas

        _bets[_tail] = b;
        _tail++; // 32byte // 20000 gas

        return true;
    }


    // QUEUE pop
    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }

}