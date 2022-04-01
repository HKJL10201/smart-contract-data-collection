// SPDX-License-Identifier: MIT
// TODO
// use SafeMath
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./AdminControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract LuckyDrawStorage {
    struct Player {
        address payable account;
        string wishes;
        string blessing;
        bool hasWinned;
        bool isWhiteList;
    }

    struct DrawInfo {
        uint8 level;
        uint8 roundIndex;
        uint8 luckyNum;
        uint256 bonus;
        bytes32[] luckyGuys;
    }

    event Registered(bytes32 codeHash, Player player);
    event DrawedOneRound(DrawInfo drawInfo);

    mapping(bytes32 => Player) public players;
    bytes32[] public playerCodeHashes;

    mapping(address => bool) public drawers;
    DrawInfo[] public drawPlans;

    uint256 public winnerCount;
    uint256 public registeredCount;

    // start from 0 to drawPlans.length-1
    uint8 public nextDrawStep;
    uint256 public drawStartTime;
    uint256 public registerStartTime;

    AdminControl adminControl =
        AdminControl(0x0888000000000000000000000000000000000000);
    address deployer;
}

contract LuckyDraw is LuckyDrawStorage {
    using SafeMath for uint256;

    receive() external payable {}

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "need admin permission");
        _;
    }

    modifier onlyDrawers() {
        require(drawers[msg.sender] == true, "need drawer permission");
        _;
    }

    modifier inDrawTime() {
        require(block.timestamp > drawStartTime, "it's not time to draw");
        _;
    }

    modifier inRegisterTime() {
        require(
            block.timestamp > registerStartTime,
            "it's not time to register"
        );
        _;
    }

    function isConflux() internal view returns (bool) {
        uint32 size;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // The Conflux create2factory contract
            size := extcodesize(0x0888000000000000000000000000000000000000)
        }
        return (size > 0);
    }

    function getAdmin() public view returns (address) {
        if (isConflux()) {
            address admin = adminControl.getAdmin(address(this));
            return admin;
        } else {
            return deployer;
        }
    }

    function initalWhiteList(bytes32[] memory codeHashes) public onlyAdmin {
        playerCodeHashes = codeHashes;
        for (uint8 i = 0; i < playerCodeHashes.length; i++) {
            Player storage p = players[playerCodeHashes[i]];
            p.isWhiteList = true;
        }
    }

    // set draw plans
    // 1. require(balance + msg.value >= sum_of_bonus)
    function addDrawPlan(
        uint8 level,
        uint8 roundIndex,
        uint8 luckyNum,
        uint256 bonus
    ) public payable onlyAdmin {
        bytes32[] storage guys;
        drawPlans.push(DrawInfo(level, roundIndex, luckyNum, bonus, guys));
        revertIfOutOfBalance();
    }

    function updateDrawers(address[] memory newDrawers) public onlyAdmin {
        for (uint256 i = 0; i < newDrawers.length; i++) {
            drawers[newDrawers[i]] = true;
        }
    }

    // register for player
    function register(
        string memory code,
        string memory wishes,
        string memory blessing
    ) public inRegisterTime {
        bytes32 codeHash = keccak256(bytes(code));
        Player storage p = players[codeHash];
        require(p.isWhiteList == true, "invalid verify code hash");
        require(p.account == address(0), "you has registered");
        p.account = msg.sender;
        p.wishes = wishes;
        p.blessing = blessing;
        registeredCount += 1;
        emit Registered(codeHash, p);
    }

    // draw, rand with salt is the random seed of the lucky guy
    function draw() public onlyDrawers inDrawTime {
        // 0. check nextDrawStep upper over flow
        require(drawPlans.length > nextDrawStep, "all darw plans has done");
        DrawInfo storage currentDraw = drawPlans[nextDrawStep];
        require(
            registeredCount.sub(winnerCount) >= currentDraw.luckyNum,
            "remain players not enough"
        );
        // 1. gen luckyguys by rand
        drawLuckyGuys();

        // 2. send cfx
        for (uint256 i = 0; i < currentDraw.luckyNum; i++) {
            bytes32 playerHash = currentDraw.luckyGuys[i];
            players[playerHash].account.transfer(currentDraw.bonus);
        }
        // 3. emit event
        emit DrawedOneRound(currentDraw);

        // 4. increase next draw step
        nextDrawStep += 1;
        winnerCount = winnerCount.add(currentDraw.luckyNum);
    }

    function drawLuckyGuys() private {
        DrawInfo storage currentDraw = drawPlans[nextDrawStep];

        uint256 salt = 0;
        while (true) {
            uint256 playerIndex = rand(salt) % playerCodeHashes.length;
            bytes32 playerHash = playerCodeHashes[playerIndex];

            if (
                players[playerHash].account != address(0) &&
                players[playerHash].hasWinned == false
            ) {
                currentDraw.luckyGuys.push(playerHash);
                players[playerHash].hasWinned = true;
            }
            if (currentDraw.luckyGuys.length >= currentDraw.luckyNum) {
                return;
            }
            salt = salt + 1234567890;
        }
    }

    function setDrawStartTime(uint256 startTime) public onlyAdmin {
        drawStartTime = startTime;
    }

    function setRegisterStartTime(uint256 startTime) public onlyAdmin {
        registerStartTime = startTime;
    }

    function reset(bool resetRegisterd, bool resetDrawPlans)
        public
        payable
        onlyAdmin
    {
        nextDrawStep = 0;
        winnerCount = 0;

        for (uint256 i = 0; i < playerCodeHashes.length; i++) {
            Player storage p = players[playerCodeHashes[i]];
            p.hasWinned = false;
            if (resetRegisterd) {
                p.account = address(0);
                delete p.blessing;
                delete p.wishes;
            }
        }

        if (resetRegisterd) {
            registeredCount = 0;
        }

        if (resetDrawPlans) {
            delete drawPlans;
        } else {
            for (uint256 i = 0; i < drawPlans.length; i++) {
                delete drawPlans[i].luckyGuys;
            }
        }

        revertIfOutOfBalance();
    }

    function revertIfOutOfBalance() private view {
        uint256 needCfx;
        for (uint256 i = 0; i < drawPlans.length; i++) {
            needCfx += uint256(drawPlans[i].luckyNum).mul(drawPlans[i].bonus);
        }
        require(
            needCfx <= address(this).balance,
            "not enough balance for bonus"
        );
    }

    function rand(uint256 salt) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number-1),
                        block.timestamp,
                        block.difficulty,
                        block.gaslimit + block.number,
                        salt
                    )
                )
            );
    }

    function getDrawPlanNum() public view returns (uint256) {
        return drawPlans.length;
    }

    function getWhiteListNum() public view returns (uint256) {
        return playerCodeHashes.length;
    }

    function checkIsRegisterd(address account) public view returns (bool) {
        Player memory p = getPlayerByAddress(account);
        return p.account == account;
    }

    function getPlayerByAddress(address account)
        public
        view
        returns (Player memory)
    {
        for (uint256 i = 0; i < playerCodeHashes.length; i++) {
            Player memory p = players[playerCodeHashes[i]];
            if (p.account == account) {
                return p;
            }
        }
    }

    function getWinners() public view returns (bytes32[] memory) {
        bytes32[] memory winners = new bytes32[](winnerCount);
        uint256 wIndex = 0;
        for (uint256 i = 0; i < playerCodeHashes.length; i++) {
            Player memory p = players[playerCodeHashes[i]];
            if (p.hasWinned) {
                winners[wIndex++] = playerCodeHashes[i];
            }
        }
        return winners;
    }

    function getRegisters() public view returns (bytes32[] memory) {
        bytes32[] memory registers = new bytes32[](registeredCount);
        uint256 rIndex = 0;
        for (uint256 i = 0; i < playerCodeHashes.length; i++) {
            Player memory p = players[playerCodeHashes[i]];
            if (p.account != address(0)) {
                registers[rIndex++] = playerCodeHashes[i];
            }
        }
        return registers;
    }
}
