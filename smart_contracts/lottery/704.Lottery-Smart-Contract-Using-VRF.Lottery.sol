pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "./RandomNumberGenerator.sol";

contract Lottery is Ownable{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using SafeMath for uint;
    
    enum LotteryState {Open, Closed, Finished}
    
    mapping(uint => EnumerableSet.AddressSet) entries;
    uint[] numbers;
    LotteryState public state;
    uint public numberOfEntries;
    uint public entryFee;
    uint public ownerCut;
    uint public winningNumber;
    address randomNumberGenerator;
    bytes32 randomNumberRequestId;
    
    event LotteryStateChanged(LotteryState newState);
    event NewEntry(address player, uint number);
    event NumberRequested(bytes32 requestId);
    event NumberDrawn(bytes32 requestId, uint winningNumber);
    
    modifier isState(LotteryState _state) {
        require(state == _state, "wrong state for this action");
        _;
    }
    
    modifier onlyRandomGenerator {
        require(msg.sender == randomNumberGenerator,"must be correct generator");
        _;
    }
    
    constructor(uint _entryFee, uint _ownerCut, address _randomNumberGenerator) public Ownable() {
        require(_entryFee > 0,'Entry Fee must be greater than zero');
        require(_ownerCut < _entryFee,'Owner Cut should be less than Entry Fee');
        require(_randomNumberGenerator != address(0),'Random Number Generator must be a valid address');
        require(_randomNumberGenerator.isContract(),'Random Number Generator must be a contract');
        entryFee = _entryFee;
        ownerCut = _ownerCut;
        randomNumberGenerator = _randomNumberGenerator;
        _changeState(LotteryState.Open);
    }
    
    function submitNumber(uint _number) public payable isState(LotteryState.Open) {
        require(msg.value >= entryFee,"the amount has to be greater than the entry fee");
        require(entries[_number].add(msg.sender),"cannot submit same number more than once");
        numbers.push(_number);
        numberOfEntries++;
        payable(owner()).transfer(ownerCut);
        emit NewEntry(msg.sender, _number);
    }
    
    function drawNumber(uint256 _seed) public onlyOwner isState(LotteryState.Open) {
        _changeState(LotteryState.Closed);
        randomNumberRequestId = RandomNumberGenerator(randomNumberGenerator).request(_seed);
        emit NumberRequested(randomNumberRequestId);
    }
    
    function rollOver() public onlyOwner isState(LotteryState.Finished) {
        
    }
    
    function numberDrawn(bytes32 _randomNumberRequestId, uint _randomNumber) public onlyRandomGenerator isState(LotteryState.Closed) {
        if(_randomNumberRequestId == randomNumberRequestId) {
            winningNumber = _randomNumber;
            emit NumberDrawn(_randomNumberRequestId, _randomNumber);
            _payout(entries[_randomNumber]);
            _changeState(LotteryState.Finished);
        }
    }
    
    function _payout(EnumerableSet.AddressSet storage winners) private {
        uint balance = address(this).balance;
        for(uint index = 0; index < winners.length(); index++) {
            payable(winners.at(index)).transfer(balance.div(winners.length()));
        }
    }
    
    function _changeState(LotteryState _newState) private {
        state = _newState;
        emit LotteryStateChanged(state);
    }
}
