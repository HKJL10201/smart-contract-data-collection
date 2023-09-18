pragma solidity ^0.4.24;

contract Lottery {
    address public creator;
    address public better;
    string public winningNumbers;
    uint256 bank;

    struct Better {
        address betterAddress;
        string bettedNumbers;
    }

    enum State { Ongoing, Finished }
    State state;

    Better[] betters;
    address[] winners;

    function Lottery()
        public
        payable
    {
        creator = msg.sender;
        state = State.Ongoing;
    }

    modifier condition(bool _condition)
    {
        require(_condition);
        _;
    }

    modifier isInState(State _state)
    {
        require(state == _state);
        _;
    }

    function bet(string _betNumbers)
        public
        condition(msg.value == (0.1 ether))
        condition(state == State.Ongoing)
        payable
    {
        if (state != State.Ongoing) {
            revert("Betting only allowed in the Finished state");
        }
        Better storage _currentBetter;
        _currentBetter.betterAddress = msg.sender;
        _currentBetter.bettedNumbers = _betNumbers;
        betters.push(_currentBetter);
        bank = bank + msg.value;
        state = State.Ongoing;
    }

    function drawWinningNumbers()
        public
    {
        if (msg.sender != creator) {
            revert("Drawing numbers only allowed for the owner");
        }
        if (state != State.Ongoing) {
            revert("Drawing numbers only allowed in the Ongoing state");
        }
        winningNumbers = "1,11,19,24,43"; // numbers need to be sorted
        state = State.Finished;
        collectWinners();
    }

    function collectWinners()
        internal
    {
        for (uint i=0; i<betters.length; i++)
        {
            if (isWinner(betters[uint(i)]))
            {
                winners.push(betters[uint(i)].betterAddress);
            }
        }
    }

    function isWinner(Better better)
        internal
        returns (bool)
    {
        string memory bettedNumbers = better.bettedNumbers;
        return keccak256(bettedNumbers) == keccak256(winningNumbers);
    }

    function payout()
        public
        payable
    {
        if(msg.sender != creator) {
            revert("Payout call only allowed for the owner");
        }
        if (state != State.Finished) {
            revert("Payout call only allowed in the Finished state");
        }
        if (winners.length > 0) {
            uint256 prize = calculatePrize();
            for (uint i=0; i<winners.length; i++)
            {
                winners[uint(i)].transfer(prize);
            }
        }
        delete winners;
        delete betters;
        delete winningNumbers;
        bank = uint256(0);
        state = State.Ongoing;
    }

    function calculatePrize()
        internal
        returns(uint256)
    {
        uint256 prizePool = bank * uint256(9) / uint256(10);
        return prizePool / uint256(winners.length);
    }

    function getWinningNumbers()
        public
        view
        returns(string memory)
    {
        return winningNumbers;
    }

    function getWinners()
        public
        view
        returns(address[] memory)
    {
        return winners;
    }

    function getState()
        public
        view
        returns(string memory)
    {
        if (state == State.Ongoing) {
            return "Ongoing";
        } else {
            return "Finished";
        }
    }

}