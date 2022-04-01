pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./Registry.sol";

contract Ballot {

    event AddVote(bytes32 did, uint256 dateMillis, address owner, uint256 delta, uint256 deposit);
    event Refund(uint256 dateMillis, address target, uint256 amount);
    event OwnershipTransferred(address old, address to);

    struct Vote {
        uint256 deposit;
        uint256 modified;
    }

    IERC20 public _token;

    address private _owner;
    address private _foundation;
    address private _rewardPool;

    mapping(address => uint256) _deposit;
    mapping(uint256 => Vote) private _totalMap;
    mapping(uint256 => mapping(bytes32 => Vote)) private _docMap;
    mapping(uint256 => mapping(bytes32 => mapping(address => Vote))) private _userMap;

    Registry private _registry;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner is allowed");
        _;
    }

    function transferOwnership(address addr) external onlyOwner() {
        require(addr != address(0), "invalid address");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    function setRegistry(address addr) external onlyOwner() {
        require(addr != address(0), "invalid address");
        _registry = Registry(addr);
    }

    function setFoundation(address foundation) external onlyOwner() {
        require(foundation != address(0), "invalid address");
        _foundation = foundation;
    }

    function setRewardPool(address rewardPool) external onlyOwner() {
        require(rewardPool != address(0), "invalid address");
        _rewardPool = rewardPool;
    }

    function setToken(address addr) external onlyOwner() {
        require(addr != address(0), "invalid address");
        _token = IERC20(addr);
    }

    function addVote(bytes32 key, uint256 deposit) external {
        _add(key, msg.sender, deposit, _registry.getBlockTimeMillis());
    }

    function upsertVote(uint256 dt, bytes32 key, address voter, uint256 deposit) external {
        require(msg.sender == _foundation, "only foundation can update votes");
        _upsert(dt, key, voter, deposit, _registry.getBlockTimeMillis());
    }

    function updateVote(uint256 dt, bytes32 key, address voter, uint256 deposit, uint256 tm) external {
        require(msg.sender == _foundation, "only foundation can update votes with time");
        require(_userMap[dt][key][voter].modified > 0, "can't find the vote");

        uint256 offset = 0;

        if (_userMap[dt][key][voter].deposit > deposit) {
            // decrease
            offset = _userMap[dt][key][voter].deposit - deposit;

            _userMap[dt][key][voter].deposit = deposit;
            _userMap[dt][key][voter].modified = tm;

            _docMap[dt][key].deposit -= offset;
            _docMap[dt][key].modified = tm;

            _totalMap[dt].deposit -= offset;
            _totalMap[dt].modified = tm;

        } else {
            // increase
            offset = deposit - _userMap[dt][key][voter].deposit;

            _userMap[dt][key][voter].deposit = deposit;
            _userMap[dt][key][voter].modified = tm;

            _docMap[dt][key].deposit += offset;
            _docMap[dt][key].modified = tm;

            _totalMap[dt].deposit += offset;
            _totalMap[dt].modified = tm;
        }
    }

    function getVoteByUser(uint256 dateMillis, bytes32 key, address voter) external view returns (uint256, uint256) {
        return (_userMap[dateMillis][key][voter].deposit, _userMap[dateMillis][key][voter].modified);
    }

    function getVoteByDocument(uint256 dateMillis, bytes32 key) external view returns (uint256, uint256) {
        return (_docMap[dateMillis][key].deposit, _docMap[dateMillis][key].modified);
    }

    function getTotalVote(uint256 dateMillis) external view returns (uint256, uint256) {
        return (_totalMap[dateMillis].deposit, _totalMap[dateMillis].modified);
    }

    function getDeposit() external view returns (uint256) {
        return _getDeposit(msg.sender);
    }

    function getDepositOfUser(address target) external view returns (uint256) {
        require(msg.sender == _foundation, "only foundation is allowed");
        return _getDeposit(target);
    }

    function _add(bytes32 key, address voter, uint256 deposit, uint256 tm) private {
        _upsert(_registry.getLastDateMillis(), key, voter, deposit, tm);
        // transfer voter's token to this contract
        _deposit[voter] += deposit;
        _token.transferFrom(voter, address(this), deposit);
    }

    function _upsert(uint256 dt, bytes32 key, address voter, uint256 deposit, uint256 tm) private {
        require(key != bytes32(0), "invalid document id");
        require(deposit > 999999999999999999, "The deposit must be bigger than 0");
        require(address(_registry) != address(0), "The registry is not set");
        require(address(_token) != address(0), "The token is not set");

        emit AddVote(key, dt, voter, deposit, _userMap[dt][key][voter].deposit + deposit);

        // write on the map for users
        if (_userMap[dt][key][voter].modified == 0) {
            Vote memory vote = Vote(deposit, tm);
            _userMap[dt][key][voter] = vote;
        } else {
            assert(_userMap[dt][key][voter].deposit + deposit > _userMap[dt][key][voter].deposit);
            _userMap[dt][key][voter].deposit += deposit;
            _userMap[dt][key][voter].modified = tm;
        }
        // write on the map for documents
        if (_docMap[dt][key].modified == 0) {
            Vote memory vote = Vote(deposit, tm);
            _docMap[dt][key] = vote;
        } else {
            assert(_docMap[dt][key].deposit + deposit > _docMap[dt][key].deposit);
            _docMap[dt][key].deposit += deposit;
            _docMap[dt][key].modified = tm;
        }
        // write on the map for day
        if (_totalMap[dt].modified == 0) {
            Vote memory vote = Vote(deposit, tm);
            _totalMap[dt] = vote;
        } else {
            assert(_totalMap[dt].deposit + deposit > _totalMap[dt].deposit);
            _totalMap[dt].deposit += deposit;
            _totalMap[dt].modified = tm;
        }
    }

    function refund(address target, uint256 amount) external {
        require(target != address(0), "invalid address");
        require(amount > 0, "amount must be bigger than 0");
        require(msg.sender == _rewardPool, "only reward pool can call refund");
        require(address(_registry) != address(0), "The registry is not set");
        require(address(_token) != address(0), "The token is not set");
        require(_token.balanceOf(address(this)) >= amount, "insufficient token");
        require(_deposit[target] > 0, "nothing to refund");
        require(_deposit[target] >= amount, "insufficient deposit to refund");

        emit Refund(_registry.getBlockTimeMillis(), target, amount);
        _deposit[target] -= amount;
        _token.transfer(target, amount);
    }

    function _getDeposit(address target) private view returns(uint256) {
        return _deposit[target];
    }
}