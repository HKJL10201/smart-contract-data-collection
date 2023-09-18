// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ILotteryNFT.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@nomiclabs/buidler/console.sol";
interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}

interface IGOT {
    function burn(uint256 amount) external;
}

interface ILottery {
    function buy(uint256 _price, uint8[4] calldata _numbers) external;

    function minPrice() external returns (uint256);
}

/**
 * @title Lotto lottery contract with 4 numbers
 * @notice 4 numbers must match in order
 */
contract Lottery is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    /// The index value of the @dev number combination is fixed at 11, because 4 numbers have 11 winning combinations
    uint8 constant keyLengthForEachBuy = 11;
    /// @dev allocates the first/second/third reward
    uint8[3] public allocation;
    /// @dev Lotto NFT address
    ILotteryNFT public lotteryNFT;
    /// @dev administrator address
    address public adminAddress;
    /// @dev maximum number
    uint8 public maxNumber = 14;
    /// @dev The lowest price, if the decimal point is not 18, please reset
    uint256  public minPrice;
    /// @notice GoSwap routing address
    address public constant GOSWAP_ROUTER = 0xd6Dc3E48bC52fd6Ff24F5318b537C46118e17F70;
    /// @notice Token for buying lottery tickets
    address public token;

    // =================================

    /// @dev issue ID => winning numbers [numbers]
    mapping(uint256 => uint8[4]) public historyNumbers;
    /// @dev release ID => [tokenId]
    mapping(uint256 => uint256[]) public lotteryInfo;
    /// @dev Issue ID => [total amount, first prize bonus, second prize bonus, third prize bonus]
    mapping(uint256 => uint256[]) public historyAmount;
    /// @dev issuance ID => lottery ticket number => total sales, total purchase amount of users
    mapping(uint256 => mapping(uint64 => uint256)) public userBuyAmountSum;
    /// @dev address => [tokenId]
    mapping(address => uint256[]) public userInfo;

    /// @dev release index
    uint256 public issueIndex = 0;
    /// Total number of @dev addresses
    uint256  public totalAddresses = 0 ;
    /// @dev Total prize pool amount
    uint256  public totalAmount = 0 ;
    /// @dev last timestamp
    uint256 public lastTimestamp;

    /// @dev winning number
    uint8[4] public winningNumbers;

    /// @dev lottery stage
    bool public drawingPhase;

    // =================================

    event Buy(address indexed user, uint256 tokenId);
    event Drawing(uint256 indexed issueIndex, uint8[4] winningNumbers);
    event Claim(address indexed user, uint256 tokenid, uint256 amount);
    event DevWithdraw(address indexed user, uint256 amount);
    event Reset(uint256 indexed issueIndex);
    event MultiClaim(address indexed user, uint256 amount);
    event MultiBuy(address indexed user, uint256 amount);

    /**
     * @dev constructor
     * @param _lotteryNFT Lottery NFT address
     * @param _token Token for buying lottery tickets
     */
    constructor(ILotteryNFT _lotteryNFT, address _token) {
        lotteryNFT = _lotteryNFT;
        adminAddress = msg.sender;
        lastTimestamp = block.timestamp;
        allocation = [50, 30, 10];
        token = _token;
    }

    /**
     * @dev Get historical winning numbers
     * @param _issueIndex release index
     * @return _numbers array of winning numbers
     */
    function getHistoryNumbers(uint256 _issueIndex) public view returns (uint8[4] memory _numbers) {
        _numbers = historyNumbers[_issueIndex];
    }

    /**
     * @dev obtains the NFT Token ID according to the issue id
     * @param _issueIndex release index
     * @return _tokenIds NFT Token ID
     */
    function getLotteryInfo(uint256 _issueIndex) public view returns (uint256[] memory _tokenIds) {
        _tokenIds = lotteryInfo[_issueIndex];
    }

    /**
     * @dev Get the historical winning amount
     * @param _issueIndex release index
     * @return _amount winning amount
     */
    function getHistoryAmount(uint256 _issueIndex) public view returns (uint256[] memory _amount) {
        _amount = historyAmount[_issueIndex];
    }

    /**
     * @dev Get all NFTs of the user
     * @param _user user address
     * @return _tokenIds NFT Token ID
     */
    function getUserInfo(address _user) public view returns (uint256[] memory _tokenIds) {
        _tokenIds = userInfo[_user];
    }

    /// @dev empty ticket
    uint8[4] internal nullTicket = [0, 0, 0, 0];

    /// @dev can only be accessed by the administrator
    modifier  onlyAdmin () {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    /// @dev After the draw
    function drawed() public view returns (bool) {
        // Return the first winning number
        return winningNumbers[0] != 0;
    }

    /**
     * @dev reset
     */
    function reset() public virtual {
        // After confirming the draw
        require(drawed(), "drawed?");
        // Last timestamp = current block timestamp
        lastTimestamp = block.timestamp;
        // Total number of addresses = 0
        totalAddresses =  0 ;
        // Total prize pool amount = 0
        totalAmount =  0 ;
        // The winning numbers are reset to zero
        winningNumbers[0] = 0;
        winningNumbers[1] = 0;
        winningNumbers[2] = 0;
        winningNumbers[3] = 0;
        // Whether the lottery stage is
        drawingPhase = false;
        // Release index +1
        issueIndex = issueIndex + 1;
        // Deal with the unsuccessful bonus and put it into the next prize pool
        uint256 amount;
        for (uint256 i = 0; i < 3; i++) {
            // If the number of people who selected (4-i) numbers in the previous period is 0
            if (getMatchingRewardAmount(issueIndex - 1, 4 - i) == 0) {
                // Amount = Last total bonus * bonus distribution ratio / 100
                amount = amount + (getTotalRewards(issueIndex - 1) * (allocation[i]) / (100));
            }
        }
        if (amount > 0) {
            // Internal purchase (buy a 0,0,0,0 lottery ticket, the purpose is to put the bonus into the next prize pool)
            _internalBuy(amount, nullTicket);
        }
        emit Reset(issueIndex);
    }

    /**
     * @dev enters the lottery stage, you must enter the lottery stage before the lottery is drawn
     */
    function enterDrawingPhase() external onlyAdmin {
        // Confirm not after the draw
        require(!drawed(), "drawed");
        // Beginning of lottery stage
        drawingPhase = true;
    }

    /**
     * @dev gets the winning number privately
     * @param _input input value
     */
    function _getNumber(bytes memory _input) private view returns (uint8) {
        // structure hash
        bytes32 _structHash;
        // random number
        uint256 _randomNumber;
        // Maximum number
        uint8 _maxNumber = maxNumber;
        // Structure hash = hash (input value)
        _structHash = keccak256(_input);
        // random number = convert the result hash to a number
        _randomNumber = uint256(_structHash);
        // Inline assembly
        assembly {
            // random number = random number% maximum number + 1
            _randomNumber := add(mod(_randomNumber, _maxNumber), 1)
        }
        // Winning number 1 = random number converted to uint8
        return uint8(_randomNumber);
    }

    /**
     * @dev draw
     * @param _externalRandomNumber external random number
     * @notice adds an external random number to prevent the node verification program from using it
     */
    function drawing(uint256 _externalRandomNumber) external onlyAdmin {
        // Confirm not after the draw
        require(!drawed(), "reset?");
        // Confirm that it is in the draw stage
        require(drawingPhase, "enter drawing phase first");
        // Block hash of the previous block
        bytes32 _blockhash = blockhash(block.number - 1);

        // Waste some gas bills here
        for (uint256 i = 0; i < 10; i++) {
            // Get the total bonus
            getTotalRewards(issueIndex);
        }
        // remaining gas
        uint256 _gasleft = gasleft ();

        // Winning number 1 (block hash of the previous block, total address number, remaining gas, external random number)
        winningNumbers[0] = _getNumber(abi.encode(_blockhash, totalAddresses, _gasleft, _externalRandomNumber));

        // Winning number 2 (block hash of the previous block, total number of awards, remaining gas, external random number)
        winningNumbers[1] = _getNumber(abi.encode(_blockhash, totalAmount, _gasleft, _externalRandomNumber));

        // Winning number 3 (block hash of the previous block, last timestamp, remaining gas, external random number)
        winningNumbers[2] = _getNumber(abi.encode(_blockhash, lastTimestamp, _gasleft, _externalRandomNumber));

        // Winning number 4 (block hash of the previous block, remaining gas, external random number)
        winningNumbers[3] = _getNumber(abi.encode(_blockhash, _gasleft, _externalRandomNumber));

        // Historical winning numbers [Issue Index] = winning numbers
        historyNumbers[issueIndex] = winningNumbers;
        // Historical bonus [issuance index] = Calculate the matching bonus amount
        historyAmount[issueIndex] = calculateMatchingRewardAmount();
        // Whether the lottery stage is
        drawingPhase = false;
        // trigger event
        emit Drawing(issueIndex, winningNumbers);
    }

    /**
     * @dev internal purchase
     * @param _price price
     * @param _numbers number array
     */
    function _internalBuy(uint256 _price, uint8[4] memory _numbers) internal {
        // Confirm not after the draw
        require(!drawed(), "drawed, can not buy now");
        // loop 4 numbers
        for (uint256 i = 0; i < 4; i++) {
            // Confirm that the number is less than or equal to the maximum number
            require(_numbers[i] <= maxNumber, "exceed the maximum");
        }
        // NFT Token ID = Create Lotto NFT
        uint256 tokenId = lotteryNFT.newLotteryItem(address(this), _numbers, _price, issueIndex);
        // Issuance index => TokenID array pushes the new TokenID
        lotteryInfo[issueIndex].push(tokenId);
        // Total number of awards + price
        totalAmount = totalAmount + (_price);
        // Last timestamp = current timestamp
        lastTimestamp = block.timestamp;
        // trigger event
        emit Buy(address(this), tokenId);
    }

    /**
     * @dev private purchase
     * @param _price price
     * @param _numbers number array
     */
    function _buy(uint256 _price, uint8[4] memory _numbers) private returns (uint256) {
        // loop 4 numbers
        for (uint256 i = 0; i < 4; i++) {
            // Confirm that the number is less than or equal to the maximum number
            require(_numbers[i] <= maxNumber, "exceed number scope");
        }
        // NFT Token ID = Create Lotto NFT
        uint256 tokenId = lotteryNFT.newLotteryItem(msg.sender, _numbers, _price, issueIndex);
        // Issuance index => TokenID array pushes the new TokenID
        lotteryInfo[issueIndex].push(tokenId);
        // If user information length=0
        if (userInfo[msg.sender].length == 0) {
            // Total number of addresses +1
            totalAddresses = totalAddresses +  1 ;
        }
        // Push the user information array into the new TokenID
        userInfo[msg.sender].push(tokenId);
        // Total amount + price
        totalAmount = totalAmount + (_price);
        // Last timestamp = current timestamp
        lastTimestamp = block.timestamp;
        // Calculate user number index
        uint64 [keyLengthForEachBuy] memory userNumberIndex =  generateNumberIndexKey (_numbers);
        // Loop 11-bit index length
        for (uint256 i = 0; i < keyLengthForEachBuy; i++) {
            // Total purchase amount of users [Issue Index] [User Number Index [i]] + Price
            userBuyAmountSum [issueIndex] [userNumberIndex [i]] = userBuyAmountSum [issueIndex] [userNumberIndex [i]]. add (_price);
        }
        return tokenId;
    }

    /**
     * @dev checker, is it available for purchase
     */
    modifier canBuy(uint256 _price) {
        // Confirm not after the draw
        require(!drawed(), "drawed, can not buy now");
        // Confirm not in the lottery stage
        require(!drawingPhase, "drawing, can not buy now");
        // Confirm that the price is greater than the minimum price
        require(_price >= minPrice, "price must above minPrice");
        _;
    }

    /**
     * @dev purchase
     * @param _price price
     * @param _numbers number array
     */
    function buy(uint256 _price, uint8[4] memory _numbers) external canBuy(_price) {
        // Private purchase
        uint256 tokenId = _buy(_price, _numbers);
        // Send the token to the current contract
        IERC20(token).safeTransferFrom(address(msg.sender), address(this), _price);
        // trigger event
        emit Buy(msg.sender, tokenId);
    }

    /**
     * @dev bulk purchase
     * @param _price price
     * @param _numbers number array
     */
    function multiBuy(uint256 _price, uint8[4][] memory _numbers) external canBuy(_price) {
        // Total cost
        uint256 totalPrice = 0 ;
        // loop number array
        for (uint256 i = 0; i < _numbers.length; i++) {
            // Private purchase
            _buy(_price, _numbers[i]);
            totalPrice = totalPrice. add (_price);
        }
        // Send the token to the current contract
        IERC20(token).safeTransferFrom(address(msg.sender), address(this), totalPrice);
        // trigger event
        emit MultiBuy ( address(msg.sender) , totalPrice);
    }

    /**
     * @dev receive rewards
     * @param _tokenId NFT Token ID
     */
    function claimReward(uint256 _tokenId) external {
        // Confirm that the caller is the NFT owner
        require(msg.sender == lotteryNFT.ownerOf(_tokenId), "not from owner");
        // Confirm NFT claim status
        require(!lotteryNFT.getClaimStatus(_tokenId), "claimed");
        // Get the amount of bonus
        uint256 reward = getRewardView(_tokenId);
        // Receive bonus
        //lotteryNFT. claimReward (_tokenId);
        // if bonus>0
        if (reward > 0) {
            // send the bonus to the user
            IERC20(token).safeTransfer(address(msg.sender), reward);
            // trigger event
            emit Claim(msg.sender, _tokenId, reward);
        }
    }

    /**
     * @dev Collect in batches
     * @param _tickets NFT Token ID array
     */
    function multiClaim(uint256[] memory _tickets) external {
        // Total bonus
        uint256 totalReward = 0 ;
        // Loop NFT Token ID array
        for (uint256 i = 0; i < _tickets.length; i++) {
            // Confirm that the caller is the NFT owner
            require(msg.sender == lotteryNFT.ownerOf(_tickets[i]), "not from owner");
            // Confirm NFT claim status
            require(!lotteryNFT.getClaimStatus(_tickets[i]), "claimed");
            // Get the amount of bonus
            uint256 reward = getRewardView(_tickets[i]);
            // if bonus>0
            if (reward > 0) {
                // Total bonus accumulation
                totalReward = reward. add (totalReward);
            }
        }
        // Collect bonuses in batches
        //lotteryNFT * claimReward(_tickets);
        // If the total prize is >0
        if (totalReward > 0) {
            // send the bonus to the user
            IERC20(token).safeTransfer(address(msg.sender), totalReward);
        }
        // trigger event
        emit  MultiClaim ( address(msg.sender) , totalReward);
    }

    /**
     * @dev calculates the number index
     * @notice 4 winning numbers have 11 winning combinations
     */
    function generateNumberIndexKey(uint8[4] memory number) public pure returns (uint64[keyLengthForEachBuy] memory) {
        // Assign the winning number to a temporary variable
        uint64[4] memory tempNumber;
        tempNumber[0] = uint64(number[0]);
        tempNumber[1] = uint64(number[1]);
        tempNumber[2] = uint64(number[2]);
        tempNumber[3] = uint64(number[3]);
        // Generate an array according to a fixed 11-bit index length
        uint64[keyLengthForEachBuy] memory result;
        /*
         * 11 winning combinations, each number in each combination is enlarged and combined into an index value
         * 0,1,2,3 = ([0] * 256^6) + (1 * 256^5 + [1] * 256^4) + (2 * 256^3 + [2] * 256^2) + (3 * 256 + [3])
         * 0,1,2 = ([0] * 256^4) + (1 * 256^3 + [1] * 256^2) + (2 * 256 + [2])
         * 0,1,3 = ([0] * 256^4) + (1 * 256^3 + [1] * 256^2) + (3 * 256 + [3])
         * 0,2,3 = ([0] * 256^4) + (2 * 256^3 + [2] * 256^2) + (3 * 256 + [3])
         * 1,2,3 = (1 * 256^5 + [1] * 256^4) + (2 * 256^3 + [2] * 256^2) + (3 * 256 + [3])
         * 0,1 = ([0] * 256^2) + (1 * 256 + [1])
         * 0,2 = ([0] * 256^2) + (2 * 256 + [2])
         * 0,3 = ([0] * 256^2) + (3 * 256 + [3])
         * 1,2 = (1 * 256^3 + [1] * 256^2) + (2 * 256 + [2])
         * 1,3 = (1 * 256^3 + [1] * 256^2) + (3 * 256 + [3])
         * 2,3 = (2 * 256^3 + [2] * 256^2) + (3 * 256 + [3])
         */
        result[0] =
            tempNumber[0] *
            256 *
            256 *
            256 *
            256 *
            256 *
            256 +
            1 *
            256 *
            256 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 *
            256 *
            256 +
            2 *
            256 *
            256 *
            256 +
            tempNumber[2] *
            256 *
            256 +
            3 *
            256 +
            tempNumber[3];

        result[1] = tempNumber[0] * 256 * 256 * 256 * 256 + 1 * 256 * 256 * 256 + tempNumber[1] * 256 * 256 + 2 * 256 + tempNumber[2];
        result[2] = tempNumber[0] * 256 * 256 * 256 * 256 + 1 * 256 * 256 * 256 + tempNumber[1] * 256 * 256 + 3 * 256 + tempNumber[3];
        result[3] = tempNumber[0] * 256 * 256 * 256 * 256 + 2 * 256 * 256 * 256 + tempNumber[2] * 256 * 256 + 3 * 256 + tempNumber[3];
        result[4] =
            1 *
            256 *
            256 *
            256 *
            256 *
            256 +
            tempNumber[1] *
            256 *
            256 *
            256 *
            256 +
            2 *
            256 *
            256 *
            256 +
            tempNumber[2] *
            256 *
            256 +
            3 *
            256 +
            tempNumber[3];

        result[5] = tempNumber[0] * 256 * 256 + 1 * 256 + tempNumber[1];
        result[6] = tempNumber[0] * 256 * 256 + 2 * 256 + tempNumber[2];
        result[7] = tempNumber[0] * 256 * 256 + 3 * 256 + tempNumber[3];
        result[8] = 1 * 256 * 256 * 256 + tempNumber[1] * 256 * 256 + 2 * 256 + tempNumber[2];
        result[9] = 1 * 256 * 256 * 256 + tempNumber[1] * 256 * 256 + 3 * 256 + tempNumber[3];
        result[10] = 2 * 256 * 256 * 256 + tempNumber[2] * 256 * 256 + 3 * 256 + tempNumber[3];

        return result;
    }

    /**
     * @dev calculates the number of matches
     * @return [Total prize pool amount, number of first prizes, number of second prizes, number of third prizes]
     */
    function calculateMatchingRewardAmount() internal view returns (uint256[4] memory) {
        // Generate an array according to a fixed 11-digit index length, and get the 11-digit index corresponding to the current winning number
        uint64[keyLengthForEachBuy] memory numberIndexKey = generateNumberIndexKey(winningNumbers);

        // First prize = total amount of user purchases [Issue Index][Index 0] (Index 0 exactly matches 4 number combinations)
        uint256 totalAmout1 = userBuyAmountSum[issueIndex][numberIndexKey[0]];

        // The sum of the second prize = the total amount of user purchases [Issue Index][Index 1~4] (Index 1~4 match the combination of 3 numbers)
        uint256 sumForTotalAmout2 = userBuyAmountSum[issueIndex][numberIndexKey[1]];
        sumForTotalAmout2 = sumForTotalAmout2 + (userBuyAmountSum[issueIndex][numberIndexKey[2]]);
        sumForTotalAmout2 = sumForTotalAmout2 + (userBuyAmountSum[issueIndex][numberIndexKey[3]]);
        sumForTotalAmout2 = sumForTotalAmout2 + (userBuyAmountSum[issueIndex][numberIndexKey[4]]);

        // Second prize = sum of second prizes-first prize * 4 (the second prize winners include the first prize winners, so 4 times the first prize will be subtracted)
        uint256 totalAmout2 = sumForTotalAmout2. sub (totalAmout1. mul ( 4 ));

        // The sum of the third prize = the total amount of user purchases [issuance index][index 5~10] (index 5~10 matches a combination of 2 numbers)
        uint256 sumForTotalAmout3 = userBuyAmountSum[issueIndex][numberIndexKey[5]];
        sumForTotalAmout3 = sumForTotalAmout3 + (userBuyAmountSum[issueIndex][numberIndexKey[6]]);
        sumForTotalAmout3 = sumForTotalAmout3 + (userBuyAmountSum[issueIndex][numberIndexKey[7]]);
        sumForTotalAmout3 = sumForTotalAmout3 + (userBuyAmountSum[issueIndex][numberIndexKey[8]]);
        sumForTotalAmout3 = sumForTotalAmout3 + (userBuyAmountSum[issueIndex][numberIndexKey[9]]);
        sumForTotalAmout3 = sumForTotalAmout3 + (userBuyAmountSum[issueIndex][numberIndexKey[10]]);

        // Third Prize = Sum of Third Prize + First Prize * 6-Sum of Second Prize * 3
        // (The third prize contains 3 second prize combinations, 6 first prize combinations, and 3 times the sum of the second prize contains 12 first prizes, so the third prize minus 3 second prizes And add back 6 first prizes
        uint256 totalAmout3 = sumForTotalAmout3 + (totalAmout1 * (6)) + (sumForTotalAmout2 * (3));
        // Return [total prize pool amount, number of first prizes, number of second prizes, number of third prizes]
        return [totalAmount, totalAmout1, totalAmout2, totalAmout3];
    }

    /**
     * @dev Get the matching bonus amount
     * @param _issueIndex release index
     * @param _matchingNumber matches several numbers, range [2,3,4], if the value is 5, the return is the total prize pool amount
     */
    function getMatchingRewardAmount(uint256 _issueIndex, uint256 _matchingNumber) public view returns (uint256) {
        return historyAmount[_issueIndex][5 - _matchingNumber];
    }

    /**
     * @dev returns the total number of historical prize pools
     * @param _issueIndex release index
     */
    function getTotalRewards(uint256 _issueIndex) public view returns (uint256) {
        // Confirm that the release index is less than the current index
        require(_issueIndex <= issueIndex, "_issueIndex <= issueIndex");

        // If it is not the state after the lottery, and the release index is the current index
        if (!drawed() && _issueIndex == issueIndex) {
            // Return the total prize pool amount
            return totalAmount;
        }
        // Return the number of prizes won in history [Issue Index][0]
        return historyAmount[_issueIndex][0];
    }

    /**
     * @dev returns the winning amount
     * @param _tokenId NFT Token ID
     * @notice bonus calculation formula: purchase price / prize pool quantity * prize pool bonus
     */
    function getRewardView(uint256 _tokenId) public view returns (uint256) {
        // Obtain the issuance index through TokenID
        uint256 _issueIndex = lotteryNFT.getLotteryIssueIndex(_tokenId);
        // Obtain the number purchased by the user through TokenID
        uint8[4] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(_tokenId);
        // Get the winning number through TokenID
        uint8[4] memory _winningNumbers = historyNumbers[_issueIndex];
        // If the winning number is 0, it means a non-existent issuance index or no prize draw
        if (_winningNumbers[0] == 0) {
            return 0;
        }

        // matching number
        uint256 matchingNumber = 0;
        // cycle number
        for (uint256 i = 0; i < lotteryNumbers.length; i++) {
            // If the winning number [i] = the number purchased by the user [i]
            if (_winningNumbers[i] == lotteryNumbers[i]) {
                // matching number + 1
                matchingNumber = matchingNumber + 1;
            }
        }
        // bonus
        uint256 reward = 0;
        // If the matched number is >1
        if (matchingNumber > 1) {
            // Quantity = unit price when purchasing lottery ticket
            uint256 amount = lotteryNFT.getLotteryAmount(_tokenId);
            // Prize pool allocation amount = total historical prize pool quantity (issuance index) * sub-quota [4-matching number] / 100 (calculate the corresponding prize pool ratio based on the current total prize pool quantity and the number of matching numbers)
            uint256 poolAmount = getTotalRewards(_issueIndex) * (allocation[4 - matchingNumber]) / (100);
            // Bonus = quantity * 1e12 / prize pool quantity (corresponding prize pool size obtained according to the issuance index and the number of matching numbers) * prize pool allocation amount
            reward = amount * (1e12) / (getMatchingRewardAmount(_issueIndex, matchingNumber)) * (poolAmount);
        }
        // return bonus / 1e12
        return reward / (1e12);
    }

    /**
     * @dev Update the administrator address through the previous developer
     * @param _adminAddress administrator address
     */
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    /**
     * @dev does not care about rewards when exiting. Emergency only
     * @param _amount amount
     */
    function adminWithdraw(uint256 _amount) public onlyOwner {
        IERC20(token).safeTransfer(address(msg.sender), _amount);
        emit DevWithdraw(msg.sender, _amount);
    }

    /**
     * @dev sets the lowest price for a ticket
     * @param _price price
     */
    function setMinPrice(uint256 _price) external onlyOwner {
        minPrice = _price;
    }

    /**
     * @dev sets the maximum number
     * @param _maxNumber maximum number
     */
    function setMaxNumber(uint8 _maxNumber) external onlyOwner {
        maxNumber = _maxNumber;
    }

    /**
     * @dev set the prize pool distribution ratio
     * @param _allcation1 Allocation ratio 1 50%
     * @param _allcation2 Allocation ratio 2 20%
     * @param _allcation3 Allocation ratio 3 10%
     */
    function setAllocation(
        uint8 _allcation1,
        uint8 _allcation2,
        uint8 _allcation3
    ) external onlyOwner {
        allocation = [_allcation1, _allcation2, _allcation3];
    }
}
