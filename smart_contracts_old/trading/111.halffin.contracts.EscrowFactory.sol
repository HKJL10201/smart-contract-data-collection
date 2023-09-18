// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Escrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./strings.sol";

contract EscrowFactory is Ownable {
    using strings for string;

    address linkToken;
    address oracle;
    bytes32 jobId;
    uint256 public maxLockPeriod;
    uint256 public productCount;
    uint256 internal constant oracleFee = 1 * 10**18;

    constructor(
        bytes32 _jobId,
        address _linkToken,
        address _oracle,
        uint256 _maxLockPeriod
    ) {
        require(_maxLockPeriod >= 0, "lock period must be greater than 0");
        linkToken = _linkToken;
        oracle = _oracle;
        jobId = _jobId;
        productCount = 0;
        maxLockPeriod = _maxLockPeriod;
    }

    event ProductCreated(address indexed seller, address product);

    function createProduct(
        string memory _name,
        uint256 _price,
        string memory _productURI,
        uint256 _lockPeriod
    ) external {
        if (_lockPeriod > maxLockPeriod) {
            _lockPeriod = maxLockPeriod;
        }

        uint256 newId = productCount;

        // address product = address(new Escrow{salt: salt}());
        address addr;
        bytes memory bytecode = type(Escrow).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(newId, msg.sender, _price));
        assembly {
            addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        Escrow(addr).setProductURI(_productURI);

        Escrow(addr).init(
            _name,
            jobId,
            linkToken,
            oracle,
            msg.sender,
            newId,
            _price,
            _lockPeriod,
            oracleFee
        );

        ERC20(linkToken).transfer(addr, 1 * oracleFee);

        productCount++;

        emit ProductCreated(msg.sender, addr);
    }

    function setMaxLockPeriod(uint256 _maxLockPeriod) external onlyOwner {
        require(_maxLockPeriod >= 0, "lock period must be greater than 0");
        maxLockPeriod = _maxLockPeriod;
    }
}
