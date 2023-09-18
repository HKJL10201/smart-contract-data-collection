pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./Registry.sol";
import "./Ballot.sol";

contract RewardPool {

    event PayRoyalty(uint256 dateMillis, address target, uint256 startDateMillis, uint256 amount);
    event PayReward(uint256 dateMillis, address target, uint256 startDateMillis, uint256 amount, uint256 refund);
    event AddRoyalty(uint256 dateMillis, address target, uint256 amount);
    event AddReward(uint256 dateMillis, address target, uint256 amount);
    event AddRefund(uint256 dateMillis, address target, uint256 amount);
    event ClaimRoyalty(uint256 dateMillis, address target, uint256 amount);
    event ClaimReward(uint256 dateMillis, address target, uint256 amount, uint256 refund);
    event OwnershipTransferred(address old, address to);

    IERC20 public _token;

    Ballot private _ballot;
    Registry private _registry;

    address private _owner;
    address private _foundation;

    mapping(address => uint256) private _royalties;
    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _refunds;

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

    function setBallot(address addr) external onlyOwner() {
        require(addr != address(0), "invalid address");
        _ballot = Ballot(addr);
    }

    function setToken(address addr) external onlyOwner() {
        require(addr != address(0), "invalid address");
        _token = IERC20(addr);
    }

    function setFoundation(address foundation) external onlyOwner() {
        require(foundation != address(0), "invalid address");
        _foundation = foundation;
    }

    function addRoyalty(uint256 dateMillis, address target, uint256 amount) external {
        require(msg.sender == _foundation, "only foundation can add royalties");
        require(target != address(0), "invalid address");
        require(amount > 0, "the amount should be bigger than 0");

        assert(_royalties[target] + amount > _royalties[target]);
        _royalties[target] += amount;

        emit AddRoyalty(dateMillis, target, amount);
    }

    function addReward(uint256 dateMillis, address target, uint256 amount) external {
        require(msg.sender == _foundation, "only foundation can add reward");
        require(target != address(0), "invalid address");
        require(amount > 0, "the amount should be bigger than 0");

        assert(_rewards[target] + amount > _rewards[target]);
        _rewards[target] += amount;

        emit AddReward(dateMillis, target, amount);
    }

    function addRewards(uint256 dateMillis, address target, uint256 amount, uint256 refund) external {
        require(msg.sender == _foundation, "only foundation can add rewards");
        require(target != address(0), "invalid address");
        require(amount > 0, "the amount should be bigger than 0");
        require(refund > 0, "the amount should be bigger than 0");

        assert(_rewards[target] + amount > _rewards[target]);
        _rewards[target] += amount;
        assert(_refunds[target] + refund > _refunds[target]);
        _refunds[target] += refund;

        emit AddReward(dateMillis, target, amount);
        emit AddRefund(dateMillis, target, refund);
    }

    function addRefund(uint256 dateMillis, address target, uint256 amount) external {
        require(msg.sender == _foundation, "only foundation can add refunds");
        require(target != address(0), "invalid address");
        require(amount > 0, "the amount should be bigger than 0");

        assert(_refunds[target] + amount > _refunds[target]);
        _refunds[target] += amount;

        emit AddRefund(dateMillis, target, amount);
    }

    function payRoyalty(uint256 dateMillis, address target, uint256 startDateMillis, uint256 amount) external {
        emit PayRoyalty(dateMillis, target, startDateMillis, amount);
        _pay(target, amount);
    }

    function payReward(uint256 dateMillis, address target, uint256 startDateMillis, uint256 amount, uint256 refund) external {
        if (refund > 0) {
            _ballot.refund(target, refund);
        }
        emit PayReward(dateMillis, target, startDateMillis, amount, refund);
        _pay(target, amount);
    }

    function _pay(address target, uint256 amount) private {
        require(target != address(0), "invalid address");
        require(amount > 0, "the amount should be bigger than 0");
        require(msg.sender == _foundation, "only foundation can pay rewards");
        require(address(_registry) != address(0), "the registry should be set");
        require(address(_ballot) != address(0), "the ballot should be set");
        require(address(_token) != address(0), "the token should be set");
        require(_token.balanceOf(address(this)) > amount, "insufficient balance");
        _token.transfer(target, amount);
    }

    function claimRoyalty() external {
        require(address(_registry) != address(0), "the registry should be set");
        require(address(_token) != address(0), "the token should be set");
        require(_royalties[msg.sender] > 0, "nothing to claim");
        uint256 amount = _royalties[msg.sender];

        emit ClaimRoyalty(_registry.getLastDateMillis(), msg.sender, amount);

        _royalties[msg.sender] = 0;
        _token.transfer(msg.sender, amount);
    }

    function claimReward() external {
        require(address(_registry) != address(0), "the registry should be set");
        require(address(_ballot) != address(0), "the ballot should be set");
        require(address(_token) != address(0), "the token should be set");
        require(_rewards[msg.sender] > 0, "nothing to claim");
        uint256 amount = _rewards[msg.sender];
        uint256 refund = _refunds[msg.sender];
        if (refund > 0) {
            _refunds[msg.sender] = 0;
            _ballot.refund(msg.sender, refund);
        }

        emit ClaimReward(_registry.getLastDateMillis(), msg.sender, amount, refund);

        _rewards[msg.sender] = 0;
        _token.transfer(msg.sender, amount);
    }
}