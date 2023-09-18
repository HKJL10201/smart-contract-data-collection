// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '../access/Ownable.sol';

contract WNSProtocol is Ownable {
    struct UserInfo {
        address addr;
        bool isVerified;
        bool isScammer;
    }

    mapping(string => bool) private _reserved;
    mapping(string => UserInfo) private _users;
    mapping(address => string) private _addresses;

    uint16 public usersCount;

    constructor() public {
        string memory _ownerName = "walletika";
        _users[_ownerName].addr = owner();
        _users[_ownerName].isVerified = true;
        _addresses[owner()] = _ownerName;
        usersCount = usersCount + 1;
        emit NewRecord(_ownerName, owner());
    }

    function isReserved(string calldata username) public view returns (bool) {
        return _reserved[username];
    }

    function isRecorded(string calldata username) public view returns (bool) {
        return _users[username].addr != address(0);
    }

    function getByName(string calldata username) external view returns (address, bool, bool) {
        return (_users[username].addr, _users[username].isVerified, _users[username].isScammer);
    }

    function getByAddress(address addr) external view returns (string memory, bool, bool) {
        string memory username = _addresses[addr];
        return (username, _users[username].isVerified, _users[username].isScammer);
    }

    function newRecord(string calldata username) external isLowercase(username) {
        require(!isRecorded(username), "Username is taken");
        require(!isReserved(username), "Username has been reserved");
        require(bytes(_addresses[_msgSender()]).length == 0, "Sender already recorded");

        _users[username].addr = _msgSender();
        _addresses[_msgSender()] = username;
        usersCount = usersCount + 1;
        emit NewRecord(username, _msgSender());
    }

    function transferUsername(address newOwner) external {
        string memory username = _addresses[_msgSender()];
        require(bytes(username).length > 0, "Sender does not have username");
        require(bytes(_addresses[newOwner]).length == 0, "newOwner already recorded");
        require(!_users[username].isScammer, "A scammer cannot transfer");

        _users[username].addr = newOwner;
        _addresses[newOwner] = username;
        _addresses[_msgSender()] = "";
        emit TransferUsername(username, _msgSender(), newOwner);
    }

    function setVerified(string calldata username, bool state) public onlyOwner {
        require(isRecorded(username), "Username is not recorded");
        require(!_users[username].isScammer, "A scammer cannot verify");

        _users[username].isVerified = state;
        emit Verified(username, _users[username].addr, state);
    }

    function setScammer(string calldata username, address addr, bool state) public onlyOwner {
        if (isRecorded(username) || bytes(_addresses[addr]).length > 0) {
            require(_users[username].addr == addr, "Address incorrect");
            if (_users[username].isVerified) {
                _users[username].isVerified = false;
            }

        } else {
            _users[username].addr = addr;
            _addresses[addr] = username;
            usersCount = usersCount + 1;
        }

        _users[username].isScammer = state;
        emit Scammer(username, addr, state);
    }

    function reserveUsers(string[] calldata users, bool[] calldata statuses) external onlyOwner {
        require(users.length <= 100, "Users exceeds 100 items");
        require(users.length == statuses.length, "Mismatch between users and statuses count");

        for (uint i=0; i < users.length; i++) {
            _reserved[users[i]] = statuses[i];
        }
    }

    function setMultiVerified(string[] calldata users, bool[] calldata statuses) external {
        require(users.length <= 100, "Users exceeds 100 items");
        require(users.length == statuses.length, "Mismatch between users and statuses count");

        for (uint i=0; i < users.length; i++) {
            setVerified(users[i], statuses[i]);
        }
    }

    function setMultiScammers(
        string[] calldata users, address[] calldata addresses, bool[] calldata statuses
    ) external {
        require(users.length <= 100, "Users exceeds 100 items");
        require(
            users.length == addresses.length && users.length == statuses.length,
            "Mismatch between users, addresses and statuses count"
        );

        for (uint i=0; i < users.length; i++) {
            setScammer(users[i], addresses[i], statuses[i]);
        }
    }

    event NewRecord(string username, address indexed owner);
    event TransferUsername(string username, address indexed owner, address indexed newOwner);
    event Verified(string username, address indexed addr, bool state);
    event Scammer(string username, address indexed addr, bool state);

    modifier isLowercase(string calldata username) {
        bytes memory bName = bytes(username);
        require(bName.length <= 40, "Username exceeds 40 characters");

        for (uint i = 0; i < bName.length; i++) {
            require(!((uint8(bName[i]) >= 65) && (uint8(bName[i]) <= 90)), "Username must be in lowercase");
        }

        _;
    }
}