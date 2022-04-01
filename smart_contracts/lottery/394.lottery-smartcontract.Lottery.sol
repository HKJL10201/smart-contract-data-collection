pragma solidity ^0.4.17;

import "./SafeMath.sol";

contract Lottery {
    mapping (address=>uint) userBets;
    mapping (uint=>address) users;
    uint totalUsers = 0;
    uint totalBets = 0;
    address owner;

    using SafeMath for uint;

    function Lottery() public {
        owner = msg.sender;
    }

    function bet() public payable {
        if (msg.value > 0) {
            if (userBets[msg.sender] == 0) {
                users[totalUsers] = msg.sender;
                totalUsers = totalUsers.add(1);
            }
            userBets[msg.sender] = userBets[msg.sender].add(msg.value);
            totalBets = totalBets.add(msg.value);
        }
    }

    // TODO: use a real random number
    function chooseWinner() public {
        if (msg.sender == owner) {
            uint sum = 0;
            uint winner = uint(block.blockhash(block.number-1) % totalBets);
            for (uint i = 0; i < totalUsers; i++) {
                sum = sum.add(userBets[users[i]]);
                if (sum >= winner) {
                    selfdestruct(users[i]);
                    return;
                }
            }
        }
    }
}