// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Mega {
    struct Ticket {
	    address payable player;
        uint[] numbers;
    }

	address payable public owner;
    address payable[] public players;
    mapping(bytes32 => Ticket[]) public hash6Tickets;
    mapping(bytes32 => Ticket[]) public hash5Tickets;
    mapping(bytes32 => Ticket[]) public hash4Tickets;
    uint[] public results;

    constructor() {
        owner = payable(msg.sender);
    }

    function play(uint[] memory numbers) public payable {
	    require(msg.value == .00035 ether);

        quickSort(numbers, int(0), int(numbers.length - 1));

        Ticket memory ticket = Ticket({ player: payable(msg.sender), numbers: numbers });

        players.push(payable(msg.sender));
        hash6Tickets[createNumbersHash(numbers, 6)].push(ticket);
        hash5Tickets[createNumbersHash(numbers, 5)].push(ticket);
        hash4Tickets[createNumbersHash(numbers, 4)].push(ticket);

        owner.transfer(msg.value * 5 / 100);
    }
	
	function getBalance() public view returns (uint) {
        return address(this).balance;
    }
	
	function setResults(uint[] memory numbers) public onlyowner {
        quickSort(numbers, int(0), int(numbers.length - 1));

        results = numbers;

        Ticket[] memory winners = hash6Tickets[createNumbersHash(numbers, 6)];

        if (winners.length == 0) {
            winners = hash5Tickets[createNumbersHash(numbers, 5)];
        }

        if (winners.length == 0) {
            winners = hash4Tickets[createNumbersHash(numbers, 4)];
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

    function quickSort(uint[] memory arr, int left, int right) internal pure {
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

    function createNumbersHash(uint[] memory numbers, uint count) internal pure returns (bytes32) {
        if (count == 5) {
            return keccak256(abi.encodePacked([numbers[0], numbers[1], numbers[2], numbers[3], numbers[4]]));
        } else if (count == 4) {
            return keccak256(abi.encodePacked([numbers[0], numbers[1], numbers[2], numbers[3]]));
        }

        return keccak256(abi.encodePacked(numbers));
    }
}
