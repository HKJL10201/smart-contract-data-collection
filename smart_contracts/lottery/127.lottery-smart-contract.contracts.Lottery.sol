// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        bytes1 challenges;
    }

    uint256 private _tail;
    uint256 private _head;
    mapping(uint256 => BetInfo) private _bets;

    address public owner;

    uint256 internal constant BLOCK_LIMIT = 256;
    uint256 internal constant BLOCK_INTERVAL = 3;
    uint256 internal constant BET_AMOUNT = 5 * 10**15; // 0.005

    uint256 private _pot;

    event BET(
        uint256 index,
        address bettor,
        uint256 amount,
        bytes1 challenges,
        uint256 answerBlockNumber
    );

    constructor() {
        owner = msg.sender;
    }

    function getPot() public view returns (uint256) {
        return _pot;
    }

    /**
     * @dev 배팅을 한다. 유저는 0.005eth를 보내야 하고, 배팅용 1bytes 글자를 보낸다.
     * Queue에 저장된 배팅 정보는 distirbute 함수에서 해결된다.
     * @param challenges 유저가 배팅하는 글자.
     * @return 함수가 잘 수행되었는지 확인하는 bool값.
     */
    function bet(bytes1 challenges) public payable returns (bool) {
        require(msg.value == BET_AMOUNT, "Not enough ETH");
        require(pushBet(challenges), "Fail to add new Bet Info");

        emit BET(
            _tail - 1,
            msg.sender,
            msg.value,
            challenges,
            block.number + BLOCK_INTERVAL
        );
        return true;
    }

    function getBetInfo(uint256 index)
        public
        view
        returns (
            uint256 answerBlockNumber,
            address bettor,
            bytes1 challenges
        )
    {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) public returns (bool) {
        BetInfo memory b;
        b.bettor = payable(msg.sender);
        b.answerBlockNumber = block.number + BLOCK_INTERVAL;
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
