//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint up;
        uint down;
        mapping(address => bool) Voters;
    }

    event tickerupdated(uint up, uint down, address voter, string ticker);

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public {
        require(Tickers[_ticker].exists, "Cant vote on this COin");
        require(
            !Tickers[_ticker].Voters[msg.sender],
            "You have already voted for this coin"
        );

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if (_vote) {
            t.up++;
        } else {
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker)
        public
        view
        returns (uint up, uint down)
    {
        require(Tickers[_ticker].exists, "No suck ticker defined");
        ticker storage t = Tickers[_ticker];
        return (t.up, t.down);
    }
}
