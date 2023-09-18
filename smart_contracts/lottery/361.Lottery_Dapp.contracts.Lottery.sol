pragma solidity >=0.4.22 <0.7.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber; // 정답 블록 6번째 등
        address payable bettor; // 돈과 관련있을때
        byte challenges; // 문제에 해당 0xab 등
    }

    address public owner;
    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;
    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15; // 0.005 eth

    uint256 private _pot;

    constructor() public {
        owner = msg.sender;
    }

    function getSomeValue() public pure returns(uint256 value) {
        return 5;
    }

    function getPot() public view returns(uint256) {
        return _pot;
    }

    // 베팅하고 검증하는게 필요!!
    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, byte challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(byte challenges) internal returns (bool) {
        BetInfo memory b;
        b.bettor = msg.sender; // 20 byte
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL; // 32byte  20000 gas
        b.challenges = challenges; // byte // 20000 gas

        _bets[_tail] = b;
        _tail++; // 32byte 값 변화 // 20000 gas -> 5000 gas
        return true;
    }

    // 값을 초기화 시킴 delete 하면 가스를 돌려받는다 -> 필요없을경우 해주기
    function popBet(uint256 index) internal returns (bool) {
        delete _bets[index];
        return true;
    }
}