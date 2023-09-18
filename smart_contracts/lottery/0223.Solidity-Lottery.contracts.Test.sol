pragma solidity ^0.6.6;

contract Test {
    // enum is a easier friendly way to represent ints, here: 0, 1, 2
    enum STATE {
        OPEN,
        CLOSED,
        CALCULATING
    }
    STATE public test_state;

    string public state;

    constructor() public {
        test_state = STATE.CLOSED;
        state = "closed";
    }

    function get_state() public view returns (STATE) {
        return test_state;
    }

    function open() public {
        require(test_state == STATE.CLOSED, "The state needs to be closed ");
    }

    function close() public {}
}
