//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
    
contract ReferendumContract is Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    event ReferendumCreated(uint indexed referendumId, string name);
    event VoteConducted(uint indexed referendumId, address payable indexed candidate, address indexed voter);
    event ReferendumEnded(uint indexed referendumId, address payable indexed winner, address indexed closer);

    fixed constant votePrice = 0.01;
    fixed constant commission = 0.1;  

    struct Referendum {
        string name;
        uint startDate;
        bool isEnded;

        address payable winner;
        address payable[] candidateAddresses;
        mapping (address => uint) candidates;

        uint numVotes;
        mapping (address => address) votes;
    }

    uint lockedBalance;
    uint numReferendums;
    mapping (uint => Referendum) referendums;

    modifier okReferendumId(uint _referendumId) { require(_referendumId >= 1 && _referendumId <= numReferendums, "Wrong referendum Id."); _; }
    modifier okAddress(address payable _address) { require(_address != address(0), "Wrong address."); _; }

    function addReferendum(string memory _name) external onlyOwner returns(uint) {
        numReferendums++;
        Referendum storage r = referendums[numReferendums];

        r.name = _name;
        r.startDate = block.timestamp;

        emit ReferendumCreated(numReferendums, _name);

        return numReferendums;
    }

    function vote(uint _referendumId, address payable _candidate) external okReferendumId(_referendumId) okAddress(_candidate) payable returns(bool) {
        require(msg.value >= .01 ether,"Making vote costs more than you provided.");
        
        Referendum storage r = referendums[_referendumId];
        require(r.votes[msg.sender]==address(0), "You already voted in this referendum.");
        require(!r.isEnded, "Referendum already ended.");

        if (r.candidates[_candidate] == 0)  r.candidateAddresses.push(_candidate);

        r.candidates[_candidate]++;
        r.numVotes++;
        r.votes[msg.sender] = _candidate;
        lockedBalance += takeCommission(msg.value);

        emit VoteConducted(_referendumId, _candidate, msg.sender);

        return true;
    }

    function endReferendum(uint _referendumId) external okReferendumId(_referendumId) returns(address) {
        Referendum storage r = referendums[_referendumId];
        require(block.timestamp - r.startDate > 3 days, "Less than three days have passed since the beginning of the referendum.");
        require(!r.isEnded, "Referendum already ended.");
        require(r.candidateAddresses.length != 0, "Seems like no one made a vote.");

        uint maxVotes=0;
        bool twoWinners;
        address payable winner;
        for (uint i = 0; i < r.candidateAddresses.length; i ++) {
            if (r.candidates[r.candidateAddresses[i]] > maxVotes) {
                maxVotes = r.candidates[r.candidateAddresses[i]];
                winner = r.candidateAddresses[i];
                twoWinners = false;
            }
            else if (r.candidates[r.candidateAddresses[i]] == maxVotes) {
                twoWinners = true;
            }
        }

        require(!twoWinners, "Two or more winners, cant end referendum.");

        r.isEnded = true;
        uint total = calculateTotal(r.numVotes);
        total = takeCommission(total);
        lockedBalance -= total;

        winner.transfer(total);

        emit ReferendumEnded(_referendumId, winner, msg.sender);

        return winner;
    }

    function withdraw(address payable _payAddress, uint _amount) external payable onlyOwner returns(bool) {
        require(_payAddress != address(0));

        if (_amount != 0) {
            require(address(this).balance.sub(lockedBalance) >= _amount, "Amount is more than avaliable balance.");
        }

        _payAddress.transfer(_amount == 0 ? address(this).balance.sub(lockedBalance) : _amount);
        return true;
    }

    function calculateTotal(uint _numVotes) private pure returns(uint) {
        return _numVotes.mul(10**18).div(100);
    }

    function takeCommission(uint _value) private pure returns(uint) {
        return _value.mul(90).div(100);
    }

    function getReferendumCount() external  view returns(uint) {
        return numReferendums;
    }

    struct ReferendumInfo {
        uint id;
        string name;
        bool isEnded;
        uint numCandidates;
        uint numVotes;
        uint startDate;
    }

    function getReferendums(uint offset, uint limit) external  view returns(ReferendumInfo[] memory) {
        require(offset <= numReferendums, "Offset is more than referendums.");
        require(limit <= 100, "Only 100 items per request.");

        uint total = Math.min(numReferendums - offset, limit);
        ReferendumInfo[] memory items = new ReferendumInfo[](total);
        for (uint i = 1; i <= total; i ++) {
            ReferendumInfo memory r =  items[i-1];
            uint id = offset + i;
            r.id = id;
            r.isEnded = referendums[id].isEnded;
            r.numCandidates = referendums[id].candidateAddresses.length;
            r.numVotes = referendums[id].numVotes;
            r.startDate = referendums[id].startDate;
        }

        return items;
    }

    function getCandidates(uint _referendumId) external okReferendumId(_referendumId) view returns(address payable[] memory) {
        Referendum storage r = referendums[_referendumId];
        return r.candidateAddresses;
    }

    function getCandidateVoteCount(uint _referendumId, address payable _candidate) external okReferendumId(_referendumId) view returns(uint) {        
        Referendum storage r = referendums[_referendumId];
        return r.candidates[_candidate];
    }
}
