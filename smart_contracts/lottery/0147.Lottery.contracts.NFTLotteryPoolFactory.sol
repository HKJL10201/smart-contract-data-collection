// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

interface INFTLotteryPool {
    function initialize(
        address _prizeAddress,
        uint256 _prizeId,
        uint64 _startDate,
        uint64 _endDate,
        uint32 _minTicketsToSell,
        uint32 _maxTickets,
        uint32 _maxTicketsPerAddress,
        uint256 _ticketPrice
    ) external;

    function transferOwnership(address newOwner) external;
}

contract NFTLotteryPoolFactory is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    CountersUpgradeable.Counter private _poolCounter;

    address public linkAddress;
    address public distributorAddress;
    uint256 public fee;

    uint256 public poolFee;
    address public template;
    struct PoolInfo {
        address seller;
        address poolAddr;
        address nftAddr;
        uint256 tokenId;
    }
    mapping(uint256 => PoolInfo) public poolIdToPoolInfos;
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _ownerToPoolIds;

    event LotteryDeployed(address pool, address deployer);

    function initialize(
        address _distributorAddress,
        address _linkAddress,
        uint256 _fee,
        address _template
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        linkAddress = _linkAddress;
        distributorAddress = _distributorAddress;
        fee = _fee;
        template = _template;
        poolFee = 0.001 ether;
    }

    function getAllPool() public view returns (PoolInfo[] memory) {
        PoolInfo[] memory allPools = new PoolInfo[](_poolCounter.current());
        for (uint256 i = 0; i < _poolCounter.current(); i++) {
            allPools[i] = poolIdToPoolInfos[i + 1];
        }
        return allPools;
    }

    function transferNft(address nftAddr, uint256 tokenId) public nonReentrant {
        IERC721Upgradeable(nftAddr).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        _poolCounter.increment();
        uint256 currentId = _poolCounter.current();
        bytes32 salt = bytes32(currentId);
        INFTLotteryPool pool = INFTLotteryPool(
            ClonesUpgradeable.cloneDeterministic(template, salt)
        );

        PoolInfo memory newInfo = PoolInfo(
            _msgSender(),
            address(pool),
            nftAddr,
            tokenId
        );
        poolIdToPoolInfos[currentId] = newInfo;
        _ownerToPoolIds[_msgSender()].add(currentId);
    }

    function createNFTLotteryPool(
        address _prizeAddress,
        uint256 _prizeId,
        uint64 _startDate,
        uint64 _endDate,
        uint32 _minTicketsToSell,
        uint32 _maxTickets,
        uint32 _maxTicketsPerAddress,
        uint256 _ticketPrice
    ) public payable nonReentrant {
        require(msg.value >= poolFee, "Pay fee");
        address pool;
        for (uint256 i = 0; i < _poolCounter.current(); i++) {
            PoolInfo memory item = poolIdToPoolInfos[i + 1];
            if (item.nftAddr == _prizeAddress && item.tokenId == _prizeId) {
                pool = item.poolAddr;
            }
        }
        require(
            pool != address(0),
            "ERROR: Non Exist Pool, Please check your transfer"
        );
        INFTLotteryPool(pool).initialize(
            _prizeAddress,
            _prizeId,
            _startDate,
            _endDate,
            _minTicketsToSell,
            _maxTickets,
            _maxTicketsPerAddress,
            _ticketPrice
        );

        // Transfers ownership of pool to caller
        INFTLotteryPool(pool).transferOwnership(msg.sender);

        // // Approve
        IERC721Upgradeable(_prizeAddress).approve(pool, _prizeId);

        // // Escrows the LINK and NFT prize
        IERC721Upgradeable(_prizeAddress).safeTransferFrom(
            address(this),
            pool,
            _prizeId
        );
        IERC20Upgradeable(linkAddress).safeTransferFrom(msg.sender, pool, fee);

        emit LotteryDeployed(pool, msg.sender);
    }

    function getLotteryAddress(bytes32 salt) public view returns (address) {
        return ClonesUpgradeable.predictDeterministicAddress(template, salt);
    }

    function updatePoolFee(uint256 f) public onlyOwner {
        poolFee = f;
    }

    function claimETH() public onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }
}
