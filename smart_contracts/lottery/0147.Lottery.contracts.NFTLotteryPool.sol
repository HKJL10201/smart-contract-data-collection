// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface ITokenURI {
    function tokenURI(uint256 id) external view returns (string memory);
}

interface ILotteryParams {
    function linkAddress() external returns (address);

    function distributorAddress() external returns (address);

    function fee() external returns (uint256);

    function masterTicketUri() external view returns (address);
}

interface IDistributor {
    function distributeToNftHolders(
        uint256 fee,
        address _nftRecipientAddress,
        uint256 startIndex,
        uint256 endIndex,
        address _rewardAddress,
        uint256 _rewardId
    ) external;
}

contract NFTLotteryPool is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    ILotteryParams private params;
    IDistributor private distributor;
    IERC20Upgradeable private link;

    // Lottery vars
    address public prizeAddress;
    uint256 public prizeId;
    uint64 public startDate;
    uint64 public endDate;
    uint32 public minTicketsToSell;
    uint32 public maxTickets;
    uint32 public maxTicketsPerAddress;
    uint256 public ticketPrice;

    // Mutex for calling VRF
    bool public hasCalledVRF;

    // Check if refunds are allowed
    bool public isRefundOpen;

    uint256 public tokenCounter;

    function initialize(
        address _prizeAddress,
        uint256 _prizeId,
        uint64 _startDate,
        uint64 _endDate,
        uint32 _minTicketsToSell,
        uint32 _maxTickets,
        uint32 _maxTicketsPerAddress,
        uint256 _ticketPrice
    ) public initializer {
        require(_endDate > _startDate, "End is before start");
        require(_minTicketsToSell > 0, "Min sell at least 1");
        require(_minTicketsToSell <= _maxTickets, "Min greater than max");
        require(_maxTicketsPerAddress >= 1, "Must be able to buy at least 1");
        OwnableUpgradeable.__Ownable_init();
        ERC721Upgradeable.__ERC721_init("NFT-LOTTERY", "LOOTOO");
        transferOwnership(_msgSender());
        params = ILotteryParams(_msgSender());
        link = IERC20Upgradeable(params.linkAddress());
        distributor = IDistributor(params.distributorAddress());
        prizeAddress = _prizeAddress;
        prizeId = _prizeId;
        startDate = _startDate;
        endDate = _endDate;
        minTicketsToSell = _minTicketsToSell;
        maxTickets = _maxTickets;
        maxTicketsPerAddress = _maxTicketsPerAddress;
        ticketPrice = _ticketPrice;
    }

    function buyTickets(uint256 numTickets) public payable {
        require(block.timestamp >= startDate, "Too early");
        require(
            balanceOf(_msgSender()).add(numTickets) <= maxTicketsPerAddress,
            "Holding too many"
        );
        require(
            tokenCounter.add(numTickets) <= maxTickets,
            "Exceeds max supply"
        );
        require(msg.value == ticketPrice.mul(numTickets), "Price incorrect");
        require(block.timestamp < endDate, "Lottery over");
        for (uint256 i = 0; i < numTickets; i++) {
            _mint(msg.sender, tokenCounter + 1);
            tokenCounter++;
        }
    }

    /**
     *  @notice Get list token ID of owner address.
     *
     *  @dev    Only admin can call this function.
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function getRefund() external nonReentrant {
        require(block.timestamp > endDate, "Lottery not over");
        require(
            tokenCounter < minTicketsToSell || !hasCalledVRF,
            "Enough tickets sold"
        );
        uint256[] memory ids = tokensOfOwner(_msgSender());
        uint256 refundAmount = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            _burn(ids[i]);
            refundAmount = refundAmount.add(ticketPrice);
        }
        payable(_msgSender()).transfer(refundAmount);
    }

    function refundOwnerAssets() public onlyOwner {
        require(block.timestamp > endDate, "Lottery not over");
        require(
            tokenCounter < minTicketsToSell || isRefundOpen,
            "Enough tickets sold"
        );
        link.safeTransfer(owner(), params.fee());
        ERC721EnumerableUpgradeable(prizeAddress).safeTransferFrom(
            address(this),
            owner(),
            prizeId
        );
    }

    function distributePrize() public onlyOwner {
        require(tokenCounter >= minTicketsToSell, "Not enough tickets sold");
        require(block.timestamp > endDate, "Lottery not over");
        require(!hasCalledVRF, "Already called VRF");
        link.approve(address(distributor), params.fee());
        ERC721EnumerableUpgradeable(prizeAddress).setApprovalForAll(
            address(distributor),
            true
        );
        distributor.distributeToNftHolders(
            params.fee(),
            address(this),
            1,
            tokenCounter,
            prizeAddress,
            prizeId
        );
        hasCalledVRF = true;
    }

    function claimETH() public onlyOwner {
        require(hasCalledVRF, "Must call VRF first");
        require(
            ERC721EnumerableUpgradeable(prizeAddress).ownerOf(prizeId) !=
                address(distributor),
            "No VRF yet"
        );
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return ITokenURI(params.masterTicketUri()).tokenURI(id);
    }
}
