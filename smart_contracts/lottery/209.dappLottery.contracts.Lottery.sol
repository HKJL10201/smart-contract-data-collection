pragma solidity ^0.8.0;

contract Lottery {
    enum State {
        IDLE,
        BETTING
    }
    address payable[] public players;
    State public currentState = State.IDLE;
    uint256 public betCount;
    uint256 public betSize;
    uint256 public houseFee;
    address public admin;

    constructor(uint256 fee) {
        require(fee > 1 && fee < 99, "fee should be between 1 and 99");
        admin = msg.sender;
        houseFee = fee;
    }

    function getPlayers() external view returns(address[] memory) {
        address[] memory _players = new address[](players.length);
        for (uint256 index = 0; index < players.length; index++) {
            _players[index] = players[index];
        }
        return _players;
    }

    function createBet(uint256 count, uint256 size)
        external
        inState(State.IDLE)
        onlyAdmin
    {
        betCount = count;
        betSize = size;
        currentState = State.BETTING;
    }

    function bet() external payable inState(State.BETTING) {
        require(msg.value == betSize, "can only bet exactly the bet size");
        players.push(payable(msg.sender));
        if (players.length == betCount) {
            uint256 winner = _randomModulo(betCount);
            players[winner].transfer(
                ((betSize * betCount) * (100 - houseFee)) / 100
            );
            currentState = State.IDLE;
            delete players;
        }
    }

    function cancel() external inState(State.BETTING) onlyAdmin {
        for (uint256 i = 0; i < players.length; i++) {
            players[i].transfer(betSize);
        }
        delete players;
        currentState = State.IDLE;
    }

    function _randomModulo(uint256 modulo) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % modulo;
    }

    modifier inState(State state) {
        require(state == currentState, "current state does not allow this");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
}
