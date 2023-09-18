// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Lottery
 * @dev Lottery 스마트 컨트랙트
 */
contract Lottery {
    // 티켓 관련
    struct Ticket {
        bytes32 id;
        uint8[6] number;
    }

    // 플레이어 관련
    struct Player {
        address payable addr;
        Ticket[] firstTickets;
        Ticket[] secondTickets;
        Ticket[] thirdTickets;
    }

    // Lottery 관련
    address public owner;
    uint256 public lotteryId = 0; // 게임 복권 갯수
    uint256 public lastLotteryId = 0;
    uint256 public contractBalance = 0;
    uint256 public nextGameBalance = 0;

    // 게임 시간
    uint256 public lotteryStart;
    uint256 public lotteryDuration = 5 minutes;
    uint256 public lotteryEnd;

    uint256 public constant ticketMax = 20;
    uint256 public constant ticketPrice = .15 ether;
    uint256 public constant cutRate = 75; // 75%, float 없음

    uint8[] public luckyNumber; // private이 그 private 아님

    // mapping(address => Player) public players;
    Player[] public players; // 모든 플레이어 돌 때 용

    address[] public firstWinners; // 역대 당첨자들
    address[] public secondWinners; // 역대 당첨자들
    address[] public thirdWinners; // 역대 당첨자들

    // mapping(address => FirstTicket[]) firstTicketMap;
    mapping(address => Ticket[]) public ticketMap; // 플레이어 찾을 때 (gas fee 위해)
    mapping(address => bool) public playerChecks; // solidity mapping existence 개념 없음

    // TEMPS
    uint256 actualPrice = 0;
    uint256 eventMoney = 0;
    uint256 firstWinner = 0;
    uint256 secondWinner = 0;
    uint256 thirdWinner = 0;
    uint256 firstMoney = 0;
    uint256 secondMoney = 0;
    uint256 thirdMoney = 0;
    uint256 nonce = 1;
    //

    // 이벤트
    event TicketsBought(address indexed _from, uint8[6] number);
    event ResetLottery();
    event LuckyNumber(uint8[6] number);

    error TooEarly(uint256 time);
    error TooLate(uint256 time);

    // Modifiers

    // 20장 삼 modifier
    modifier enoughTicket() {
        if (ticketMap[msg.sender].length > ticketMax)
            revert("Too many tickets");
        _;
    }

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    modifier enoughMoney() {
        if (msg.value < ticketPrice) {
            revert("Not enough money");
        } else {
            _;
        }
    }

    modifier onlyBefore(uint256 time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }

    modifier onlyAfter(uint256 time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    modifier enoughLottery() {
        if (contractBalance == 0 || lotteryId == 0) {
            revert("Not enough lottery");
        } else {
            _;
        }
    }

    /** ------------ Functions ------------ **/

    constructor() {
        owner = msg.sender;
        lotteryId = 0;

        // Time
        lotteryStart = block.timestamp;
        lotteryEnd = lotteryStart + lotteryDuration;
    }

    // TODO: ChainLink VRF 써서 unpredictable random number generate 하기
    function random(uint256 dom) private returns (uint256) {
        uint256 rand = (uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    keccak256(abi.encodePacked(nonce)),
                    msg.sender
                )
            )
        ) % dom) + 1;
        nonce++;
        return rand; // 1 ~ dom
    }

    // 일반적 절차: BUY - PICK - SEND
    // 한번에 최대 20장은 살 수 있음
    // dApp에서 넘버 생성 누르면 번호 뜨고 그 옆에 몇 장 살껀지도
    // lotteryOngoing
    function buyTicket()
        public
        payable
        enoughTicket
        onlyBefore(lotteryEnd)
        returns (uint8[6] memory numbers)
    {
        // if (msg.value < amount * ticketPrice) {
        //     return false; // 또는 돈 만큼 티켓 사주기
        // }

        if (playerChecks[msg.sender] == false) {
            // uint256 id = players.length;
            Player storage p = players.push(); // solidity 언어가 너무 이상, 일단 empty space 추가
            p.addr = payable(msg.sender);
            playerChecks[msg.sender] = true;
        }

        uint8[6] memory number = [
            uint8(1),
            uint8(2),
            uint8(3),
            uint8(random(7)),
            uint8(random(7)),
            uint8(random(7))
        ];

        ticketMap[msg.sender].push(
            Ticket(keccak256(abi.encodePacked(block.timestamp, nonce)), number)
        );

        contractBalance += msg.value;
        lotteryId++; // dApp 에서 로또 총 몇개 팔렸는지 쉽게
        emit TicketsBought(msg.sender, number);
        return number;
    }

    function pickWinner()
        public
        payable
        onlyAfter(lotteryEnd)
        enoughLottery
        restricted
    {
        // 플레이어 없음
        if (lotteryId == 0) {
            revert("No player");
        }

        luckyNumber = [
            uint8(1),
            uint8(2),
            uint8(random(7)),
            uint8(random(7)),
            uint8(random(7)),
            uint8(random(7))
        ];

        for (uint256 i = 0; i < players.length; i++) {
            Player storage player = players[i];
            if (ticketMap[player.addr].length == 0) continue;

            for (uint256 j = 0; j < ticketMap[player.addr].length; j++) {
                Ticket memory ticket = ticketMap[player.addr][j];
                uint8 counts = 0;

                for (uint8 t = 0; t < 6; t++) {
                    if (luckyNumber[t] == ticket.number[t]) counts++;
                }

                if (counts == 6) {
                    firstWinner++;
                    player.firstTickets.push(ticket);
                    firstWinners.push(player.addr);
                } else if (counts >= 4) {
                    // 차피 6은 포함 안된 if
                    secondWinner++;
                    player.secondTickets.push(ticket);
                    secondWinners.push(player.addr);
                } else if (counts >= 2) {
                    thirdWinner++;
                    player.thirdTickets.push(ticket);
                    thirdWinners.push(player.addr);
                }
            }
        }

        sendMoney();
    }

    function sendMoney() public payable restricted enoughLottery {
        actualPrice = (contractBalance / 100) * cutRate; // 75%, fixed point도 없음;

        if (firstWinner == 0) {
            nextGameBalance += (actualPrice / 100) * 70;
        } else {
            firstMoney = ((actualPrice / 100) * 70) / firstWinner;
        }

        if (secondWinner == 0) {
            nextGameBalance += (actualPrice / 100) * 15;
        } else {
            secondMoney = ((actualPrice / 100) * 15) / secondWinner;
        }

        if (thirdWinner == 0) {
            nextGameBalance += (actualPrice / 100) * 15;
        } else {
            thirdMoney = ((actualPrice / 100) * 15) / thirdWinner;
        }

        for (uint256 i = 0; i < players.length; i++) {
            Player storage player = players[i];

            eventMoney += player.firstTickets.length * firstMoney;
            eventMoney += player.secondTickets.length * secondMoney;
            eventMoney += player.thirdTickets.length * thirdMoney;

            if (player.firstTickets.length > 0) {
                player.addr.transfer(player.firstTickets.length * firstMoney);
            }
            if (player.secondTickets.length > 0) {
                player.addr.transfer(player.secondTickets.length * secondMoney);
            }
            if (player.thirdTickets.length > 0) {
                player.addr.transfer(player.thirdTickets.length * thirdMoney);
            }
        }
    }

    // lotteryFinished
    function resetLottery()
        public
        restricted
        onlyAfter(lotteryEnd)
        returns (bool success)
    {
        lotteryStart = block.timestamp;
        lotteryEnd = lotteryStart + lotteryDuration;

        contractBalance -= actualPrice;
        contractBalance += nextGameBalance;
        nextGameBalance = 0;
        
        firstWinner = 0;
        secondWinner = 0;
        thirdWinner = 0;
        delete firstWinners;
        delete secondWinners;
        delete thirdWinners;

        lastLotteryId = lotteryId;
        lotteryId = 0;

        for (uint256 i = 0; i < players.length; i++) {
            Player storage player = players[i];
            playerChecks[player.addr] = false;
            delete ticketMap[player.addr];
        }
        delete players;
        // TODO mapping reset?

        emit ResetLottery();
        return true;
    }

    /** ------------ Getter ------------ **/

    function getPlayers() public view returns (Player[] memory) {
        return players;
    }

    function getFirstWinners() public view returns (address[] memory) {
        return firstWinners;
    }

    function getSecondWinners() public view returns (address[] memory) {
        return secondWinners;
    }

    function getThirdWinners() public view returns (address[] memory) {
        return thirdWinners;
    }

    function getTickets(address sender) public view returns (Ticket[] memory) {
        return ticketMap[sender];
    }

    // function getTicketAmount(address sender) public view returns (uint256) {
    //     return ticketMap[sender].length;
    // }

    function getLuckyNumber() public view returns (uint8[] memory) {
        return luckyNumber;
    }

    function getLottoId() public view returns (uint256) {
        return lotteryId;
    }

    function getWinMoney() public view returns (uint256) {
        return contractBalance;
    }

    function getFirstMoney() public view returns (uint256) {
        return firstMoney;
    }

    function getSecondMoney() public view returns (uint256) {
        return secondMoney;
    }

    function getThirdMoney() public view returns (uint256) {
        return thirdMoney;
    }

    function getTicketPrice() public pure returns (uint256) {
        return ticketPrice;
    }

    function getNextMoney() public view returns (uint256) {
        return nextGameBalance;
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getEndTime() public view returns (uint256) {
        return lotteryEnd;
    }
}
