//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Lotto {
    uint private ticketPrice;
    mapping(string => address[]) private players;
    string[] private playerKeys;
    string private lastResult;
    uint private seed;

    constructor() payable {
        /*
         * Set the initial seed used for random number generation
         */
        seed = (block.timestamp + block.difficulty) % 100;
        ticketPrice = 0.001 ether;
    }
    
    function play(uint[] memory numbers) payable public {
        validateEntry(numbers);
        
        string memory key = arrayAsString(sort(numbers));
        addPlayer(key, msg.sender);
        
        string memory winner = arrayAsString(sort(getCheatingResult()));
        if (players[winner].length != 0) {
            payWinners(winner);
            resetPlayers();
        }
    }
    
    function payWinners(string memory key) private {
        uint256 priceMoney = address(this).balance/players[key].length;
        for (uint i = 0; i < players[key].length; i++) {
            payable(players[key][i]).transfer(priceMoney);    
        }
    }
    
    function resetPlayers() private {
        for (uint i = 0; i < playerKeys.length; i++) {
            delete players[playerKeys[i]];
        }
        delete playerKeys;
    }
    
    function addPlayer(string memory key,address sender) private {
        addPlayerKey(key);
        
        if (players[key].length != 0) {
            addAddress(key, sender);
            return;
        }
        players[key] = [sender];
    }
    
    function addAddress(string memory key, address sender) private {
        for (uint i = 0; i < players[key].length; i++) {
            if (players[key][i] == sender) {
                return;
            }
        }
        players[key].push(sender);
    }
   
    function addPlayerKey(string memory key) private {
        for (uint i = 0; i < playerKeys.length; i++) {
            if (keccak256(abi.encodePacked(playerKeys[i])) == keccak256(abi.encodePacked(key))) {
                return;
            }
        }
        playerKeys.push(key);
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function getTicketPrice() public view returns(uint) {
        return ticketPrice;
    }
    
    function arrayAsString(uint[] memory array) private pure returns(string memory) {
        string memory result = "[";
        for (uint i = 0; i < array.length; i++) {
            result = string.concat(result, Strings.toString(array[i]));
            if (i != array.length -1) {
                result = string.concat(result, ",");
            }
        }
        
        return string.concat(result, "]");
    }
    
    
    function validateEntry(uint[] memory numbers) private view {
        require(numbers.length == 6, "lotto must have only 6 numbers");
        
        // check range of numbers
        for (uint i=0; i<numbers.length; i++) {
            require(numbers[i] >= 1 && numbers[i] <= 50, "numbers must be between [1, 50] inclusive");
        }
        
        isUnique(numbers);

        require(msg.value == ticketPrice, "the value must be the ticket price of 0.01 ether");
    }
    
    function isUnique(uint[] memory numbers) private pure {
        for (uint i=0; i<numbers.length; i++) {
            for (uint j=i+1; j<numbers.length; j++) {
                require(numbers[i] != numbers[j], "the input cannot have duplicate entries.");
            }
        }
    }

    function getCheatingResult() private view returns (uint[] memory) {
        uint[] memory result = new uint[](6);
        
        result[0] = 1;
        result[1] = 2;
        result[2] = 3;
        result[3] = 4;
        result[4] = 5;
        result[5] = 6;
        
        return result;
    }
    
    function getResult() private view returns (uint[] memory) {
        uint[] memory result = new uint[](6);
        
        uint limit = 6;
        uint index = 0;
        
        for (uint i = 0; i < limit ; i++) {
            uint value = random(i);
            if (canInsert(result, value)) {
                result[index] = value;
                index++;
            } else {
                limit++;
            }
        }
        return result;
    }
    
    function canInsert(uint[] memory result, uint value) private pure returns(bool) {
        for (uint j = 0; j < result.length; j++) {
            if (result[j] == value) {
                return false;
            }
        }
        return true;
    }

    function random(uint epsilon) private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed, epsilon)));
        return (randomHash % 50) + 1;
    }

    function sort(uint[] memory data) private pure returns(uint[] memory) {
        quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function quickSort(uint[] memory arr, int left, int right) private pure{
        int i = left;
        int j = right;
        if(i==j) return;
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
}
