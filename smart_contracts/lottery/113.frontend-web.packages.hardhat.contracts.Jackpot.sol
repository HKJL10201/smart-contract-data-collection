//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./ColorsNFT.sol";
import "./ColorModifiers.sol";
import "hardhat/console.sol";

contract Jackpot is VRFConsumerBase, Ownable {
    //VRF variables
    bytes32 internal keyHash;
    uint256 internal fee;

    bytes32 private requestId;

    address payable admin;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    // countdown to finish lottery
    uint256 deadline;

    LOTTERY_STATE public lottery_state;
    uint256 public winningColor;

    //Addresses of subcontracts

    address public colorsNFTAddress;
    address public colorModifiersAddress;

    //Contracts

    ColorModifiers colorModifiers;
    ColorsNFT colorsNFT;

    receive() external payable {}

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        // admin = payable(msg.sender);
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK

        // Define and deploy subcontracts

        // TD change this to a only fixed address when final version of colorModifiers is ready
        colorModifiers = new ColorModifiers(address(this));
        colorModifiersAddress = address(colorModifiers);

        //TD need to define a way that colorsNFT only accepts he ERC1155 tokens from colorModifiersAddress
        colorsNFT = new ColorsNFT(colorModifiersAddress, address(this));
        colorsNFTAddress = address(colorsNFT);
        lottery_state = LOTTERY_STATE.OPEN;

        startLottery();
    }

    // Owner functions to start restart Lottery

    function startLottery() public onlyOwner {
        // start count down.. when it is done you can execute end lottery
        require(
            lottery_state == LOTTERY_STATE.OPEN,
            "Can't start if it is not closed"
        );
        deadline = block.timestamp + 2 minutes;
        winningColor = 0;
    }

    function restartLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can't restart until finished"
        );
        colorModifiers = new ColorModifiers(address(this));
        colorModifiersAddress = address(colorModifiers);

        colorsNFT = new ColorsNFT(colorModifiersAddress, address(this));
        colorsNFTAddress = address(colorsNFT);
        lottery_state = LOTTERY_STATE.OPEN;
        startLottery();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return (deadline - block.timestamp);
        }
    }

    function endLottery() public {
        require(block.timestamp >= deadline, "Countdown has not finished!");
        // Rinkeby chainid
        if (block.chainid == 4) {
            if (colorsNFT.totalSupply() > 0) {
                lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
                requestId = getRandomNumber();
            } else {
                lottery_state = LOTTERY_STATE.CLOSED;
            }
        } else {
            if (colorsNFT.totalSupply() > 0) {
                lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

                uint256 randomNumber = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            colorsNFT.totalSupply()
                        )
                    )
                ) % (2**24);

                distributeWinnings(randomNumber);
            } else {
                lottery_state = LOTTERY_STATE.CLOSED;
            }
        }
    }

    function getRandomNumber() public returns (bytes32 _requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(_requestId != 0, "Currently not expecting any randomness!");
        require(_requestId == requestId, "Invalid request ID for randomness!");

        requestId = 0;

        distributeWinnings(_randomness % (2**24));
    }

    // TODO Public for testing only! Make this private before going to production!
    function distributeWinnings(uint256 jackpotColor) public {
        lottery_state = LOTTERY_STATE.CLOSED;
        winningColor = jackpotColor;

        uint256 minDistance = 2**256 - 1;
        address payable[] memory winners = new address payable[](
            colorsNFT.totalSupply()
        );
        uint256 numberWinners;

        uint256 currDistance;
        for (uint256 i = 0; i < colorsNFT.totalSupply(); i++) {
            if (colorsNFT.tokenToOwner(i) == address(0)) {
                continue;
            }

            currDistance = colorsNFT.colorDistance(
                winningColor,
                colorsNFT.tokenToColor(i)
            );
            if (currDistance < minDistance) {
                minDistance = currDistance;
                winners[0] = colorsNFT.tokenToOwner(i);
                numberWinners = 1;
            } else if (currDistance == minDistance) {
                winners[numberWinners] = colorsNFT.tokenToOwner(i);
                numberWinners++;
            }
        }

        uint256 amountToSend = (address(this).balance / numberWinners);
        for (uint256 i = 0; i < numberWinners; i++) {
            // Use `send` to transfer money and ignore all errors. Otherwise, smart contracts entering into the lottery
            // and refusing to accept their winnings may block the system forever.
            winners[i].send(amountToSend);
        }
    }
}
