// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

import "./NFT.sol";

contract Lottery {
    // Ticket bought by the user
    struct Ticket {
        uint256[5] numbers;
        uint256 powerball;
        address owner;
    }

    // Collectible is represented by a tokenId and the related image url
    struct Collectible {
        uint256 id;
        string image;
    }

    /// Round is open
    event RoundOpened(uint256 _startingBlock, uint256 _finalBlock);

    /// Lottery is closed
    event LotteryClosed();

    /// Create a nft for a collectible
    event TokenMinted(address _to, uint256 _tokenId, string _image);

    /// User buys a ticket
    event TicketBought(
        address _buyer,
        uint256 _one,
        uint256 _two,
        uint256 _three,
        uint256 _four,
        uint256 _five,
        uint256 _powerball
    );

    /// Winning numbers are announced
    event WinningNumbersDrawn(
        uint256 _one,
        uint256 _two,
        uint256 _three,
        uint256 _four,
        uint256 _five,
        uint256 _powerball
    );

    event PrizeAssigned(address _to, uint256 _tokenId, string _image);

    event RoundFinished();

    string public constant COLLECTIBLES_REPO =
        "https://github.com/fedehsq/nft_lottery/master/blob/collectibles/";

    address public manager;
    uint256 public roundDuration;
    uint256 private endRoundBlock;
    uint256 private kParam = 0;
    uint256 private tokenId = 0;

    bool private lotteryActive;
    bool private numbersExtracted;
    bool private roundFinished;

    uint256 public constant TICKET_PRICE = 1 ether;

    NFT private nft;

    // Mapping between the class that the collectible belongs to and the collectible
    mapping(uint256 => Collectible[]) private collectibles;

    Ticket[] private tickets;

    Ticket private winningTicket;

    /// @notice msg.sender is the owner of the contract
    /// @param _nftAddress address of the nft contract
    /// @param _roundDuration The duration of the round in block numbers.
    constructor(address _nftAddress, uint256 _roundDuration) payable {
        require(_roundDuration < 1000, "Round duration must be less than 1000");
        manager = msg.sender;
        nft = NFT(_nftAddress);
        roundDuration = _roundDuration;
        lotteryActive = true;
        // Open the furst new round
        endRoundBlock = block.number + roundDuration + 1;
        emit RoundOpened(block.number, endRoundBlock);
    }

    /// @notice The lottery operator can open a new round.
    /// The lottery operator can only open a new round if the previous round is finished.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    /// @dev Throws unless the lottery is active
    /// @dev Throws if the round is yet open
    function openRound() public {
        require(lotteryActive, "Lottery is not active");
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(!isRoundActive(), "Round is already active");
        require(numbersExtracted, "Numbers have not been extracted yet");
        require(roundFinished, "Round is not finished yet");
        delete tickets;
        delete winningTicket;
        roundFinished = false;
        numbersExtracted = false;
        endRoundBlock = block.number + roundDuration + 1;
        emit RoundOpened(block.number, endRoundBlock);
    }

    /// @notice The lottery operator can close the contract.
    /// If the round is active, refunds the users who bought tickets.
    /// @dev Throws unless `msg.sender` is the current owner or the lottery is not finished
    /// @dev Throws unless the lottery is active
    function closeLottery() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        if (isRoundActive()) {
            for (uint256 i = 0; i < tickets.length; i++) {
                payable(tickets[i].owner).transfer(TICKET_PRICE);
            }
        }
        lotteryActive = false;
        emit LotteryClosed();
    }

    /// @notice The lottery operator mints n nft.
    /// @param nToken the number of nft to mint
    function mintNtoken(uint256 nToken) public {
        for (uint256 i = 0; i < nToken; i++) {
            mint();
        }
    }

    /// @notice The lottery operator can mint new token.
    /// The name of the image is the tokenId.
    /// @dev Throws unless `msg.sender` is the current owner or the class (rank) is not valid
    /// @dev Throws unless the lottery is active
    /// @dev Throws unless the number of collectibles is less than 8 or the number of tickets
    function mint() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        tokenId++;
        uint256 class = (tokenId % 8) + 1;
        string memory image = string(
            abi.encodePacked(
                COLLECTIBLES_REPO,
                Strings.toString(tokenId),
                ".svg"
            )
        );
        collectibles[class].push(Collectible(tokenId, image));
        nft.mint(tokenId, image);
        emit TokenMinted(msg.sender, tokenId, image);
    }

    /// @notice Buy 'random' tickets.
    /// @param nTickets Number of tickets to buy
    function buyNRandomTicket(uint256 nTickets) public payable {
        require(
            msg.value == TICKET_PRICE * nTickets,
            "You need to send n ether"
        );
        for (uint256 i = 0; i < nTickets; i++) {
            uint256 _one = ((i + 1) % 69) + 1;
            uint256 _two = ((i + 2) % 69) + 1;
            uint256 _three = ((i + 3) % 69) + 1;
            uint256 _four = ((i + 4) % 69) + 1;
            uint256 _five = ((i + 5) % 69) + 1;
            uint256 _powerball = ((i + 6) % 25) + 1;
            buyTicket(_one, _two, _three, _four, _five, _powerball);
        }
    }

    /// @notice The user can buy a ticket.
    /// @dev Throws unless `one`, `two`, `three`, `four`, `five`, `six` are valid numbers
    /// @dev Throws unless `msg.sender` has enough ether to buy the ticket
    /// @dev Throws unless `ticket` is unique
    /// @dev Throws unless the lottery is active
    /// @dev Throws unless the numbers are different one from each other
    /// @param _one The first number of the ticket
    /// @param _two The second number of the ticket
    /// @param _three The third number of the ticket
    /// @param _four The fourth number of the ticket
    /// @param _five The fifth number of the ticket
    /// @param _powerball The special powerball number of the ticket
    function buy(
        uint256 _one,
        uint256 _two,
        uint256 _three,
        uint256 _four,
        uint256 _five,
        uint256 _powerball
    ) public payable {
        require(msg.value == TICKET_PRICE, "You need to send 1 ether");
        buyTicket(_one, _two, _three, _four, _five, _powerball);
    }

    /// @notice Create a ticket.
    function buyTicket(
        uint256 _one,
        uint256 _two,
        uint256 _three,
        uint256 _four,
        uint256 _five,
        uint256 _powerball
    ) internal {
        require(lotteryActive, "Lottery is not active");
        require(isRoundActive(), "Round is not active");
        require(_one >= 1 && _one <= 69, "Invalid number");
        require(_two >= 1 && _two <= 69, "Invalid number");
        require(_three >= 1 && _three <= 69, "Invalid number");
        require(_four >= 1 && _four <= 69, "Invalid number");
        require(_five >= 1 && _five <= 69, "Invalid number");
        require(_powerball >= 1 && _powerball <= 26, "Invalid number");
        require(
            _one != _powerball &&
                _two != _powerball &&
                _three != _powerball &&
                _four != _powerball &&
                _five != _powerball,
            "Numbers must be different one from each other"
        );
        uint256[5] memory ticketNumbers = sortTicketNumbers(
            _one,
            _two,
            _three,
            _four,
            _five
        );
        checkOrderedNumbers(ticketNumbers);
        tickets.push(Ticket(ticketNumbers, _powerball, msg.sender));
        emit TicketBought(
            msg.sender,
            _one,
            _two,
            _three,
            _four,
            _five,
            _powerball
        );
    }

    /// @notice Check if the round is active.
    /// The round is active if the current block number < endRoundBlock
    /// @return True if the round is active, false otherwise.
    function isRoundActive() public view returns (bool) {
        return endRoundBlock > block.number;
    }

    /// @notice Generate a random int.
    /// @return A random int.
    function generateRandomNumber(uint256 seed) private view returns (uint256) {
        require(
            block.number >= kParam + endRoundBlock,
            "Not enough blocks to generate random number"
        );
        return
            uint256(
                keccak256(abi.encode(blockhash(kParam + endRoundBlock), seed))
            );
    }

    /// @notice Draw winning numbers of the current lottery round
    /// @dev Throws unless `msg.sender` is the lottery operator
    /// @dev Throws unless `winner` is not defined
    /// @dev Throws unless `winningTicket` is not defined
    /// @dev Throws unless the lottery is active
    function drawNumbers() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        require(!isRoundActive(), "Round is not yet finished");
        require(!roundFinished, "Round is already finished");
        require(!numbersExtracted, "Won numbers are already drawn");

        uint256 one = (generateRandomNumber(1) % 69) + 1;
        uint256 two = (generateRandomNumber(2) % 69) + 1;
        uint256 three = (generateRandomNumber(3) % 69) + 1;
        uint256 four = (generateRandomNumber(4) % 69) + 1;
        uint256 five = (generateRandomNumber(5) % 69) + 1;
        uint256 six = (generateRandomNumber(6) % 26) + 1;
        winningTicket = Ticket(
            sortTicketNumbers(one, two, three, four, five),
            six,
            address(0)
        );
        numbersExtracted = true;
        emit WinningNumbersDrawn(one, two, three, four, five, six);
    }

    /// @notice Distribute the prizes of the current lottery round
    /// @dev Throws unless `msg.sender` is the lottery operator
    /// @dev Throws unless `winner` is not defined
    /// @dev Throws unless `winningTicket` is already drawn
    /// @dev Throws unless the lottery is active
    function givePrizes() public {
        require(
            msg.sender == manager,
            "Only the operator con do this operation"
        );
        require(lotteryActive, "Lottery is not active");
        require(!isRoundActive(), "Round is not yet finished");
        require(numbersExtracted, "Won numbers are not drawn");
        require(!roundFinished, "Round is already finished");
        for (uint256 i = 0; i < tickets.length; i++) {
            // Check how many numbers count the winning ticket numbers
            uint256 count = 0;
            bool powerballMatch = false;
            for (uint256 j = 0; j < 5; j++) {
                if (
                    binarySearch(tickets[i].numbers[j], winningTicket.numbers)
                ) {
                    count++;
                }
            }
            // Check if the powerball matches the winning ticket powerball
            if (tickets[i].powerball == winningTicket.powerball) {
                powerballMatch = true;
            }
            if (count > 0 || powerballMatch) {
                uint256 classPrize = getClassPrize(count, powerballMatch);
                uint256 id = 0;
                // if the class is empty, mint a new collectible for the winner
                if (collectibles[classPrize].length == 0) {
                    mint();
                    id = tokenId;
                    nft.transferFrom(address(this), tickets[i].owner, id);
                } else {
                    uint256 collectibleIndex = tokenId %
                        collectibles[classPrize].length;
                    id = collectibles[classPrize][collectibleIndex].id;
                    // check if the contract has the ability to transfer the collectible
                    if (
                        nft.ownerOf(id) == address(this) ||
                        nft.getApproved(id) == address(this) ||
                        nft.isApprovedForAll(nft.ownerOf(id), address(this))
                    ) {
                        nft.transferFrom(address(this), tickets[i].owner, id);
                    } else {
                        // mint a new collectible for the winner
                        mint();
                        id = tokenId;
                        nft.transferFrom(address(this), tickets[i].owner, id);
                    }
                }
                emit PrizeAssigned(
                    tickets[i].owner,
                    id,
                    string(
                        abi.encodePacked(
                            COLLECTIBLES_REPO,
                            Strings.toString(tokenId),
                            ".svg"
                        )
                    )
                );
            }
        }

        // Send the tickets cash to the owner
        payable(manager).transfer(tickets.length * TICKET_PRICE);

        roundFinished = true;
        emit RoundFinished();
    }

    /// @notice Binary search to find if a number is in an array of numbers
    /// @param number The number to search for
    /// @param numbers The array of numbers to search in
    /// @return True if the number is in the array, false otherwise
    function binarySearch(uint256 number, uint256[5] memory numbers)
        internal
        pure
        returns (bool)
    {
        uint256 left = 0;
        uint256 right = numbers.length - 1;
        while (left <= right) {
            uint256 mid = (left + right) / 2;
            if (numbers[mid] == number) {
                return true;
            } else if (numbers[mid] < number) {
                left = mid + 1;
            } else if (mid == 0) {
                return false;
            } else {
                right = mid - 1;
            }
        }
        return false;
    }

    /// @notice Get the class prize of the current lottery round based on the number of matching numbers
    /// @param _count The number of matching numbers
    /// @param _powerballMatch True if the powerball matches the winning ticket powerball, false otherwise
    /// @dev Throws unless the lottery is active
    /// @return The class prize
    function getClassPrize(uint256 _count, bool _powerballMatch)
        internal
        view
        returns (uint256)
    {
        require(lotteryActive, "Lottery is not active");
        if (_count == 5) {
            if (_powerballMatch) {
                return 1;
            }
            return 2;
        } else if (_count == 4) {
            if (_powerballMatch) {
                return 3;
            }
            return 4;
        } else if (_count == 3) {
            if (_powerballMatch) {
                return 4;
            }
            return 5;
        } else if (_count == 2) {
            if (_powerballMatch) {
                return 5;
            }
            return 6;
        } else if (_count == 1) {
            if (_powerballMatch) {
                return 6;
            }
            return 7;
        } else if (_powerballMatch) {
            return 8;
        }
        return 0;
    }

    /// @notice Build the tickets number in ascending order
    /// @param _one The first number
    /// @param _two The second number
    /// @param _three The third number
    /// @param _four The fourth number
    /// @param _five The fifth number
    /// @return The ticket numbers in ascending order
    function sortTicketNumbers(
        uint256 _one,
        uint256 _two,
        uint256 _three,
        uint256 _four,
        uint256 _five
    ) internal pure returns (uint256[5] memory) {
        // Order the numbers in ascending order
        uint256[5] memory numbers = [_one, _two, _three, _four, _five];
        uint256 temp;
        for (uint256 i = 0; i < numbers.length; i++) {
            for (uint256 j = i + 1; j < numbers.length; j++) {
                if (numbers[i] > numbers[j]) {
                    temp = numbers[i];
                    numbers[i] = numbers[j];
                    numbers[j] = temp;
                }
            }
        }
        return numbers;
    }

    /// @notice Check if the numbers are different from each other
    /// @param _orderedNumbers The ordered numbers
    /// @dev Throws if the numbers are the same
    function checkOrderedNumbers(uint256[5] memory _orderedNumbers)
        internal
        pure
    {
        for (uint256 i = 0; i < _orderedNumbers.length - 1; i++) {
            require(
                _orderedNumbers[i] != _orderedNumbers[i + 1],
                "Numbers are equals"
            );
        }
    }
}
