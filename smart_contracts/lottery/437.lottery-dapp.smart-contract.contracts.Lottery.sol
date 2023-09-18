//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Lottery is Ownable, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address[2] public managers;
    IERC20 public bbt;
    uint256 public totalLotteries = 0;
    uint256 public totalEntries = 0;
    mapping(uint256 => mapping(uint256 => address)) public entries;
    uint256 public ticketPrice;
    uint256 public pricePool;
    uint256 public lastDrawTime;

    constructor(IERC20 token) {
        bbt = token;
        ticketPrice = 25 ether;
        lastDrawTime = block.timestamp;
        _grantRole(OWNER_ROLE, msg.sender);
        _setRoleAdmin(MANAGER_ROLE, OWNER_ROLE);
        grantRole(MANAGER_ROLE, msg.sender);
    }

    function setManager(bool isFirstManager, address newManagerAddress)
        public
        onlyOwner
    {
        if (isFirstManager) {
            if (address(0) != managers[0])
                revokeRole(MANAGER_ROLE, managers[0]);
            grantRole(MANAGER_ROLE, newManagerAddress);
            managers[0] = newManagerAddress;
        } else {
            if (address(0) != managers[0])
                revokeRole(MANAGER_ROLE, managers[1]);
            grantRole(MANAGER_ROLE, newManagerAddress);
            managers[1] = newManagerAddress;
        }
    }

    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice * 1 ether;
    }

    function getEntry(uint256 lotteryIndex, uint256 entryIndex)
        public
        view
        returns (address)
    {
        return entries[lotteryIndex][entryIndex];
    }

    function enter(uint256 _totalTikets) public payable {
        require(_totalTikets > 0, "Must by atleast one tiket.");
        /// transfer the tokens to lottery contract
        bbt.transferFrom(msg.sender, address(this), ticketPrice * _totalTikets);
        /// add tokens to the current pool
        pricePool = pricePool + (ticketPrice * _totalTikets);
        /// enter the user _totalTikets number of times
        for (uint256 i = totalEntries; i < totalEntries + _totalTikets; i++) {
            entries[totalLotteries][i] = msg.sender;
        }
        totalEntries = totalEntries + _totalTikets;
    }

    function draw() public fiveMinsPassed managerAcess {
        // pick the sudo winner
        require(totalEntries > 0, "No one entered");
        uint256 randomIndex = random() % totalEntries;
        address _winner = entries[totalLotteries][randomIndex];
        // reset
        lastDrawTime = block.timestamp;
        totalEntries = 0;
        totalLotteries += 1;
        // send the coind to the winner after 5% maintaiance fee
        bbt.transfer(_winner, (pricePool * 95) / 100);
        // reset pricePool
        pricePool = 0;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        totalEntries
                    )
                )
            );
    }

    modifier managerAcess() {
        require(
            hasRole(MANAGER_ROLE, msg.sender) || owner() == msg.sender,
            "Sender is not manager"
        );
        _;
    }

    modifier fiveMinsPassed() {
        require(
            lastDrawTime + 5 minutes < block.timestamp,
            "5 minutes has to pass."
        );
        _;
    }
}
