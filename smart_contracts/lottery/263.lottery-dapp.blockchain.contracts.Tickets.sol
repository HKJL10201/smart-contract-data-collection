//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Tickets is Ownable, VRFConsumerBase {
    constructor(
        address vrfCoordinator_,
        address link_,
        bytes32 keyHash_,
        uint256 fee_,
        uint128 ticketPrice_,
        uint128 prize_,
        uint16 qtyOfTicketsToSell_,
        uint16 qtyOfEarlyBirds_,
        uint8 qtyOfWinners_
    ) VRFConsumerBase(vrfCoordinator_, link_) {
        _keyHash = keyHash_;
        _fee = fee_;

        setTicketPrice(ticketPrice_);
        setPrize(prize_);
        setQtyOfTicketsToSell(qtyOfTicketsToSell_);
        setQtyOfEarlyBirds(qtyOfEarlyBirds_);
        setQtyOfWinners(qtyOfWinners_);
    }

    event RoundEnded(
        uint16 roundNumber,
        uint16 qtyOfWinners,
        address[] winners,
        uint256 totalPrize,
        uint256 PrizeEach,
        uint256 timestamp
    );

    // Chainlink VRF
    bytes32 private _keyHash;
    uint256 private _fee;

    // Configurables
    uint128 public ticketPrice; // wei
    uint128 public prize; // wei to be split between qtyOfWinners
    uint16 public qtyOfTicketsToSell; // round ends when this number of tickets is sold
    uint16 public qtyOfEarlyBirds; // initial entrants to receive bonus ticket upon purchase
    uint16 public qtyOfWinners; // quantity of entrants to split prize

    struct EntrantLatestDetails {
        uint16 latestRound;
        uint16 qtyOfTicketsOwned; // sold & bonus tickets
    }

    mapping(address => EntrantLatestDetails) private entrantDetails; // entrant => latest round participated, num of tickets
    mapping(uint16 => address) private ticketToOwner; // contains sold & bonus tickets
    uint16 public soldTickets = 0;
    uint16 public bonusTickets = 0; // obtained through referring or early bird purchases
    uint16 public totalTickets = 0;
    uint16 public currentRound = 1;
    uint16 public qtyOfEntrants = 0;
    bool public roundResetInProcess = false;

    function setTicketPrice(uint128 newTicketPrice) public onlyOwner {
        ticketPrice = newTicketPrice;
    }

    function setPrize(uint128 newPrize) public onlyOwner {
        require(roundResetInProcess == false, "Round is currently resetting");
        prize = newPrize;
    }

    function setQtyOfTicketsToSell(uint16 newQtyOfTicketsToSell)
        public
        onlyOwner
    {
        require(newQtyOfTicketsToSell >= 1, "Must be at least 1");
        qtyOfTicketsToSell = newQtyOfTicketsToSell;
    }

    function setQtyOfEarlyBirds(uint16 newQtyOfEarlyBirds) public onlyOwner {
        require(
            newQtyOfEarlyBirds <= qtyOfTicketsToSell,
            "Must be less than qtyOfTicketsToSell"
        );
        qtyOfEarlyBirds = newQtyOfEarlyBirds;
    }

    function setQtyOfWinners(uint16 newQtyOfWinners) public onlyOwner {
        require(newQtyOfWinners >= 1, "Must be at least 1");
        require(
            newQtyOfWinners <= qtyOfTicketsToSell,
            "Must be less than qtyOfTicketsToSell"
        );
        require(roundResetInProcess == false, "Round is currently resetting");
        qtyOfWinners = newQtyOfWinners;
    }

    function getEntrantQtyOfTickets(address entrantAddress)
        external
        view
        returns (uint16)
    {
        uint16 latestRound = entrantDetails[entrantAddress].latestRound;
        uint16 qtyOfTicketsOwned = entrantDetails[entrantAddress]
            .qtyOfTicketsOwned;
        if (latestRound < currentRound) {
            return 0;
        } else {
            return qtyOfTicketsOwned;
        }
    }

    function buyTicket() external payable buyTicketModifier {
        _buyTicket();
    }

    function buyTicketWithReferral(address referrer)
        external
        payable
        buyTicketModifier
    {
        if (entrantDetails[referrer].latestRound == currentRound) {
            bonusTickets += 1;
            totalTickets += 1;
            entrantDetails[referrer].qtyOfTicketsOwned += 1;
        } // else transaction continues without referral bonus

        _buyTicket();
    }

    modifier buyTicketModifier() {
        require(msg.value == ticketPrice, "Value does not match ticket price");
        require(roundResetInProcess == false, "Round is currently resetting");
        require(soldTickets < qtyOfTicketsToSell, "Round's tickets sold out");
        _;
    }

    function _buyTicket() private {
        soldTickets += 1;
        ticketToOwner[(soldTickets - 1) + bonusTickets] = msg.sender;

        if (soldTickets <= qtyOfEarlyBirds) {
            // Early bird
            bonusTickets += 1;
            totalTickets += 2;
            ticketToOwner[(bonusTickets - 1) + soldTickets] = msg.sender;
            entrantDetails[msg.sender].qtyOfTicketsOwned += 2;
        } else {
            totalTickets += 1;
            entrantDetails[msg.sender].qtyOfTicketsOwned += 1;
        }

        // New entrant to round
        if (entrantDetails[msg.sender].latestRound != currentRound) {
            entrantDetails[msg.sender].latestRound = currentRound;
            qtyOfEntrants++;
        }

        if (soldTickets >= qtyOfTicketsToSell) {
            _endOfRound();
        }
    }

    function _endOfRound() private {
        require(
            LINK.balanceOf(address(this)) >= _fee,
            "Unable to reset round: insufficient LINK"
        );
        roundResetInProcess = true;
        requestRandomness(_keyHash, _fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        roundResetInProcess = false;
        if (qtyOfEntrants < qtyOfWinners) qtyOfWinners = qtyOfEntrants;
        address[] memory winnerSelection = new address[](qtyOfWinners);
        uint16 qtyOfTicketsRemaining = totalTickets; // decreases as tickets are selected and removed

        for (uint16 i = 0; i < qtyOfWinners; i++) {
            uint16 winnerIndex = _getRandomTicketNumber(
                randomness,
                qtyOfTicketsRemaining
            );
            address winnerAddress = ticketToOwner[winnerIndex];
            winnerSelection[i] = ticketToOwner[winnerIndex];

            // Removing the winner from the pool
            ticketToOwner[winnerIndex] = ticketToOwner[
                qtyOfTicketsRemaining - 1
            ];
            qtyOfTicketsRemaining--;

            // Duplicate winner check
            if (i > 0) {
                winnerAddress = _checkForDuplicateWinner(
                    i,
                    winnerIndex,
                    winnerAddress,
                    winnerSelection,
                    randomness,
                    qtyOfTicketsRemaining
                );
            }

            winnerSelection[i] = winnerAddress;
        }
        _distributePrize(winnerSelection);
        emit RoundEnded(
            currentRound,
            uint16(winnerSelection.length),
            winnerSelection,
            prize,
            prize / winnerSelection.length,
            block.timestamp
        );
        _resetRound();
    }

    function _getRandomTicketNumber(
        uint256 randomness,
        uint16 qtyOfTicketsRemaining
    ) private pure returns (uint16) {
        uint16 selectedRandomValue = uint16(randomness % qtyOfTicketsRemaining);
        return selectedRandomValue;
    }

    function _checkForDuplicateWinner(
        uint16 currentSizeOfWinners,
        uint16 winnerIndex,
        address winnerAddress,
        address[] memory winnerSelection,
        uint256 randomness,
        uint16 qtyOfTicketsRemaining
    ) private returns (address) {
        bool duplicateFound = false;
        for (uint16 j = 0; j < currentSizeOfWinners; j++) {
            if (
                winnerAddress == winnerSelection[j] && qtyOfTicketsRemaining > 0
            ) {
                winnerIndex = _getRandomTicketNumber(
                    randomness,
                    qtyOfTicketsRemaining
                );
                winnerAddress = ticketToOwner[winnerIndex];
                duplicateFound = true;

                // Removing the winner from the pool
                ticketToOwner[winnerIndex] = ticketToOwner[
                    qtyOfTicketsRemaining - 1
                ];
                qtyOfTicketsRemaining--;

                break;
            }
        }
        if (duplicateFound == true) {
            return
                _checkForDuplicateWinner(
                    currentSizeOfWinners,
                    winnerIndex,
                    winnerAddress,
                    winnerSelection,
                    randomness,
                    qtyOfTicketsRemaining
                );
        } else {
            return winnerAddress;
        }
    }

    function _distributePrize(address[] memory winnerSelection) private {
        uint256 prizeEach = prize / winnerSelection.length;
        for (uint16 i = 0; i < winnerSelection.length; i++) {
            (bool success, ) = winnerSelection[i].call{
                value: uint256(prizeEach)
            }("");
            require(success, "Unsuccessful transfer");
        }
    }

    function _resetRound() private {
        currentRound++;
        soldTickets = 0;
        bonusTickets = 0;
        totalTickets = 0;
        qtyOfEntrants = 0;
    }

    function withdrawSurplus() external onlyOwner {
        int256 surplus = int256(address(this).balance - prize);
        require(surplus > 0, "Insufficient balance");
        (bool success, ) = owner().call{value: uint256(surplus)}("");
        require(success, "Unsuccessful transfer");
    }

    function withdrawLink(uint256 amount) external onlyOwner {
        LinkTokenInterface linkToken = LinkTokenInterface(LINK);
        require(amount <= linkToken.balanceOf(address(this)));
        require(linkToken.transfer(owner(), amount), "Unsuccessful transfer");
    }
}
