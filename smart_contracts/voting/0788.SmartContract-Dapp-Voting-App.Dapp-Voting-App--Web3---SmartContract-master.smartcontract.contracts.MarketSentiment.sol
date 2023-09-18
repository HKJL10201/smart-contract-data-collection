//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract MarketSentiment {
    address public owner;
    string[] public tickersArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerupdated(
        uint256 up,
         uint256 down, 
         address voter, 
         string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public{
        require(msg.sender==owner,"Sadece sahibi etiket olusturabilir");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists= true;
        tickersArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) public{
        require(Tickers[_ticker].exists, "Bu coine oy veremezsiniz.");
        require(!Tickers[_ticker].Voters[msg.sender], "Zaten bir coine oy verdiniz.");


        ticker storage t= Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.up++;
        }else{
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }


    function getVotes(string memory _ticker) public view returns(
        uint256 up,
        uint256 down
    ){
        require(Tickers[_ticker].exists, "Boyle bir Ticker Tanimlanmadi.");
        ticker storage t = Tickers[_ticker];
        return(t.up,t.down);
    }





}
