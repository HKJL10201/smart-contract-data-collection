// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Mega {
    event Played (address player, uint8[6] numbers);

    struct Ticket {
        address payable player;
        uint8[6] numbers;
    }

    uint public price;
    address payable public owner;
    address payable[] public players;
    mapping(bytes32 => Ticket[]) public hash6Tickets;
    mapping(bytes32 => Ticket[]) public hash5Tickets;
    mapping(bytes32 => Ticket[]) public hash4Tickets;
    uint8[6] public results;

    constructor() {
        owner = payable(msg.sender);
        price = .00035 ether;
    }

    function play(uint8[6] memory _numbers) public payable {
        require(msg.value == price, "Games costs .00035 ether");
        require(validateNumbers(_numbers), "All numbers must be unique and between 1 and 60");

        quickSort(_numbers, int(0), int(_numbers.length - 1));

        Ticket memory ticket = Ticket({ player: payable(msg.sender), numbers: _numbers });

        players.push(payable(msg.sender));
        hash6Tickets[createNumbersHash(_numbers, 6)].push(ticket);
        hash5Tickets[createNumbersHash(_numbers, 5)].push(ticket);
        hash4Tickets[createNumbersHash(_numbers, 4)].push(ticket);

        owner.transfer(msg.value * 5 / 100);

        emit Played(msg.sender, _numbers);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function setPrice(uint _price) public onlyowner {
        require(price > 0, "Invalid price");

        price = _price;
    }

    function setResults(uint8[6] memory _numbers) public onlyowner {
        require(validateNumbers(_numbers), "All numbers must be unique and between 1 and 60");

        quickSort(_numbers, int(0), int(_numbers.length - 1));

        results = _numbers;

        Ticket[] memory winners = hash6Tickets[createNumbersHash(_numbers, 6)];

        if (winners.length == 0) {
            winners = hash5Tickets[createNumbersHash(_numbers, 5)];
        }

        if (winners.length == 0) {
            winners = hash4Tickets[createNumbersHash(_numbers, 4)];
        }

        if (winners.length > 0) {
            uint prize = address(this).balance / winners.length;

            for (uint i = 0; i < winners.length; i++) {
                winners[i].player.transfer(prize);
            }
        } else {
            uint refund = address(this).balance / players.length;

            for (uint i = 0; i < players.length; i++) {
                players[i].transfer(refund);
            }
        }
    }

    modifier onlyowner() {
        require(msg.sender == owner, "Only owners can execute this function");
        _;
    }

    function validateNumbers(uint8[6] memory numbers) internal pure returns (bool) {
        for (uint i = 0; i < numbers.length; i++) {
            if (numbers[i] < 1 || numbers[i] > 60) {
                return false;
            }

            for (uint j = i + 1; j < numbers.length; j++) {
                if (j != i && numbers[j] == numbers[i]) {
                    return false;
                }
            }
        }

        return true;
    }

    function quickSort(uint8[6] memory arr, int left, int right) internal pure {
        int i = left;
        int j = right;

        if (i == j) return;

        uint pivot = arr[uint(left + (right - left) / 2)];

        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }

        if (left < j)
            quickSort(arr, left, j);

        if (i < right)
            quickSort(arr, i, right);
    }

    function createNumbersHash(uint8[6] memory numbers, uint count) internal pure returns (bytes32) {
        if (count == 5) {
            return keccak256(abi.encodePacked([numbers[0], numbers[1], numbers[2], numbers[3], numbers[4]]));
        } else if (count == 4) {
            return keccak256(abi.encodePacked([numbers[0], numbers[1], numbers[2], numbers[3]]));
        }

        return keccak256(abi.encodePacked(numbers));
    }
}
