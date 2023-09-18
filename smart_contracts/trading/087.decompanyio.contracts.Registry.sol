pragma solidity ^0.5.0;

contract Registry {

    event AddDocument(bytes32 did, uint256 timestamp, address owner, bytes32 hashed);
    event UpdateDocument(bytes32 did, uint256 timestamp, address owner, bytes32 hashed);
    event SetDate(uint256 dateMillis);
    event OwnershipTransferred(address old, address to);

    struct Document {
        uint256 dateMillis;
        address owner;
        bytes32 hashed;
        uint256 modified;
    }

    bytes32[] private _list;
    mapping(bytes32 => Document) private _map;
    mapping(bytes32 => bytes32) private _exists;

    address private _owner;
    address private _foundation;
    uint256 public _startDateMillis;
    uint256 public _dateMillis;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner is allowed");
        _;
    }

    function setFoundation(address foundation) external onlyOwner() {
        require(foundation != address(0), "invalid address");
        _foundation = foundation;
    }

    function transferOwnership(address addr) external onlyOwner() {
        require(addr != address(0), "invalid address");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    function setDateMillis(uint256 dateMillis) external {
        require(dateMillis > 0, "invalid date");
        require(msg.sender == _foundation, "only foundation can set dateMillis");
        if (_startDateMillis == 0) {
            _startDateMillis = dateMillis;
        }
        emit SetDate(_dateMillis);
        _dateMillis = dateMillis;
    }

    function addDocument(bytes32 key, bytes32 hashed) external {
        require(key != bytes32(0), "invalid document id");
        require(hashed != bytes32(0), "invalid hash value");
        require(_foundation != address(0), "not initialized");
        require(_dateMillis > 0, "not initialized");
        require(_exists[hashed] == bytes32(0), "same hash already exists");
        require(_map[key].dateMillis == 0, "already exists");

        if (_dateMillis < getBlockDateMillis()) {
            _dateMillis = getBlockDateMillis();
        }

        emit AddDocument(key, _dateMillis, msg.sender, hashed);

        Document memory doc = Document(_dateMillis, msg.sender, hashed, _dateMillis);
        _map[key] = doc;
        _list.push(key);
        _exists[hashed] = key;
    }

    function updateDocument(bytes32 key, bytes32 hashed) external {
        require(key != bytes32(0), "invalid document id");
        require(hashed != bytes32(0), "invalid hash value");
        require(_exists[hashed] == bytes32(0), "same hash already exists");
        require(_map[key].dateMillis > 0, "document does not exist");
        require(_map[key].owner == msg.sender, "only document owner can update");

        if (_dateMillis < getBlockDateMillis()) {
            _dateMillis = getBlockDateMillis();
        }

        emit UpdateDocument(key, _dateMillis, msg.sender, hashed);

        _map[key].hashed = hashed;
        _map[key].modified = _dateMillis;
        _exists[hashed] = key;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function getDocument(bytes32 key) external view returns (uint256, address, bytes32, uint256) {
        return (_map[key].dateMillis, _map[key].owner, _map[key].hashed, _map[key].modified);
    }

    function getDocumentByHash(bytes32 hashed) external view returns (bytes32) {
        return _exists[hashed];
    }

    function count() external view returns (uint256) {
        return _list.length;
    }

    function getLastDateMillis() public view returns (uint) {
        require(_dateMillis > 0, "should be initialized");
        require(_dateMillis >= getBlockDateMillis(), "a new transaction is required to determine exact date.");
        return _dateMillis;
    }

    function getBlockDateMillis() public view returns (uint) {
        return uint(getBlockTimeMillis() / 86400000) * 86400000;
    }

    function getBlockTimeMillis() public view returns (uint) {
        return uint(block.timestamp * 1000);
    }
}
