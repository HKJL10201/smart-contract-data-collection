// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteContract is Ownable {
    // address public owner;
    uint constant DURATION = 3 days;
    uint constant FEE = 10; // 10%
    uint public voteNumber = 0; // количество голосований (id голосования)
    uint public price = 10000000000000000; // сумма участия в голосовании 0.01 eth
    uint public summFee = 0; // сумма комиссий, которую можно вывести

    // Кандидат
    struct Candidate {
        uint candyNum;
        string name;
        address candyAddr;
        uint voteCount; // количество голосов
    }

    // Голосование
    struct Vote {
        string title;
        uint startAt;
        uint endsAt;
        // mapping (uint => Candidate) candidate;
        Candidate[] candidates; // список кандидатов
        address[] participants; // список участников
        uint voutingBudget; // сумма внесённых средств за минусом 10%
        string winner;
        bool stopped;
    }

    mapping(uint => Vote) public votes;
    
    // Функция создания голосования
    function createVote(string memory _title, string[] memory _candidates, address[] memory _candyAddr, uint _duration) public onlyOwner returns(string memory) {
        uint duration = _duration == 0 ? DURATION : _duration;
        voteNumber++;
        votes[voteNumber].title = _title;
        votes[voteNumber].startAt = block.timestamp;
        votes[voteNumber].endsAt = block.timestamp + duration;
        for(uint256 i = 0; i < _candidates.length; i++) {
            Candidate memory newCandidate = Candidate({
                candyNum: i+1,
                name: _candidates[i],
                candyAddr: payable(_candyAddr[i]),
                voteCount: 0
            });
            for(uint256 j = 0; j < votes[voteNumber].candidates.length; j++) {
                if (newCandidate.candyAddr == votes[voteNumber].candidates[j].candyAddr) {
                    delete votes[voteNumber];
                    voteNumber--;
                    return "Candidates don't repeate";
                }
            }
            votes[voteNumber].candidates.push(newCandidate);
        }
        return "Vote created successfully!";
    }

    // Функция голосования
    function addVoice(uint voteNum, uint candidateNum) public payable {
        require(msg.value >= price, "not enough fund");
        require(block.timestamp < votes[voteNum].endsAt, "voting is over");
        for(uint256 i = 0; i < votes[voteNum].participants.length; i++) {
            require(votes[voteNum].participants[i] != msg.sender, "you cannot re-vote");
        }
        votes[voteNum].participants.push(msg.sender);
        votes[voteNum].voutingBudget += (msg.value - ((msg.value * FEE) / 100));
        summFee += (msg.value * FEE) / 100;
        for(uint256 i = 0; i < votes[voteNum].candidates.length; i++) {
            if(votes[voteNum].candidates[i].candyNum == candidateNum)
                votes[voteNum].candidates[i].voteCount++;
        }
    }

    // Функция вывода комиссии
    function withdrawFee(address addr, uint summ) public onlyOwner {
        address payable _to = payable(addr);
        require(summ < summFee, "withdrawal limim exceeded");
        _to.transfer(summ);
        summFee -= summ;
    }

    // Функция просмотра информации о голосовании
    function infoVote(uint _numVote) public view returns(Vote memory) {
        return votes[_numVote];
    }

    // Функция просмотра информации о кандидатах голосования
    function infoCandidate(uint _numVote) public view returns(Candidate[] memory) {
        return votes[_numVote].candidates;
    }

    // Функция просмотра информации об участниках голосования
    function infoParticipants(uint _numVote) public view returns(address[] memory) {
        return votes[_numVote].participants;
    }

    // Функция завершения голосования
    function endVote(uint _numVote) public {
        require(block.timestamp > votes[_numVote].endsAt, "voting is still active");
        require(votes[_numVote].stopped == false, "voting has ended");
        bool flag;
        if(msg.sender == owner()) {
            flag = true;
        } else {
            for(uint256 i = 0; i < votes[_numVote].participants.length; i++) {
                if(msg.sender == votes[_numVote].participants[i]) {
                    flag = true;
                    break;
                }
            }
        }
        require(flag, "You must be a participant");
        // Поиск победителя
        uint points = 0;
        Candidate memory _winner;
        for(uint256 i = 0; i < votes[_numVote].candidates.length; i++) {
            if(votes[_numVote].candidates[i].voteCount > points) {
                points = votes[_numVote].candidates[i].voteCount;
                _winner = votes[_numVote].candidates[i];
            }
        }
        if(votes[_numVote].voutingBudget != 0) {
            votes[_numVote].winner = _winner.name;
            address payable _to = payable(_winner.candyAddr);
            _to.transfer(votes[_numVote].voutingBudget);
            votes[_numVote].voutingBudget = 0;
        } else {
            votes[_numVote].winner = "No winner";
        }
        votes[_numVote].stopped = true;
    }

    // Показать общий баланс контракта
    function currentBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }
}