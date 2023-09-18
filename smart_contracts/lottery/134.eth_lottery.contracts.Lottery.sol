// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable {
    bool public isOpen;

    uint256 lastLotteryTimestamp = block.timestamp;

    uint32 minFee = 10000 wei;
    uint256 currentValue = 0;

    uint8 currentPercent = 20;
    uint16 participantCount = 0;
    uint16 maxParticipants = 100;

    struct Player {
        string name;
        address playerAddress;
        uint256 value;
    }

    mapping(address => string) public participants;

    event Transfer(address _from, uint256 _value);

    function setIsOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    function updateLastLotteryTimestamp() private {
        lastLotteryTimestamp = block.timestamp;
    }

    function fiveMinutesHavePassed() public view returns (bool) {
        return (block.timestamp >= (lastLotteryTimestamp + 5 minutes));
    }

    function transfer(string memory name) public payable {
        require(
            participantCount < maxParticipants,
            "There is no more space for you to join"
        );
        require(msg.value >= minFee, "Need more ETH to access Lottery");
        require(
            bytes(participants[msg.sender]).length == 0,
            "You can't participate more than once in the lottery"
        );

        currentValue += msg.value;

        participants[msg.sender] = name;
        participantCount++;

        emit Transfer(msg.sender, msg.value);
    }

    function getPercentValue(uint8 percent) public view returns (uint256) {
        return currentValue * (percent / 100);
    }

    function sendEthToWinners(address payable[] memory currentWinners)
        public
        payable
        onlyOwner
        returns (bool)
    {
        for (uint16 i = 0; i < currentWinners.length; i++) {
            uint256 curWinnerEther = getPercentValue(currentPercent);
            bool sent = currentWinners[i].send(curWinnerEther);

            if (sent) {
                currentValue -= curWinnerEther;

                if (i == 0) currentPercent /= 2;

                if (i > 3) currentPercent = uint8((currentValue / 96) * 100);
            }
        }

        updateLastLotteryTimestamp();

        return true;
    }
}
