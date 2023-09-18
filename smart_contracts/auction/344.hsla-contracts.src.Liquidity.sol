//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/AddressUpgradeable.sol";
import "./interfaces/compound/ICEther.sol";
import "./interfaces/compound/ICERC20.sol";
import "./interfaces/niftyapes/liquidity/ILiquidity.sol";
import "./interfaces/niftyapes/lending/ILending.sol";
import "./interfaces/niftyapes/offers/IOffers.sol";
import "./interfaces/sanctions/SanctionsList.sol";
import "./lib/Math.sol";

/// @title NiftyApes Liquidity
/// @custom:version 1.0
/// @author captnseagraves (captnseagraves.eth)
/// @custom:contributor dankurka
/// @custom:contributor 0xAlcibiades (alcibiades.eth)
/// @custom:contributor zjmiller (zjmiller.eth)

contract NiftyApesLiquidity is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ILiquidity
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    /// @dev Internal address used for for ETH in our mappings
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @dev Internal constant address for the Chainalysis OFAC sanctions oracle
    address private constant SANCTIONS_CONTRACT = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;

    /// @inheritdoc ILiquidity
    mapping(address => address) public override assetToCAsset;

    /// @notice The reverse mapping for assetToCAsset
    mapping(address => address) internal _cAssetToAsset;

    /// @notice The account balance for each cAsset of a user
    mapping(address => mapping(address => uint256)) internal _balanceByAccountByCAsset;

    /// @inheritdoc ILiquidity
    mapping(address => uint256) public override maxBalanceByCAsset;

    /// @inheritdoc ILiquidity
    address public lendingContractAddress;

    /// @inheritdoc ILiquidity
    uint16 public regenCollectiveBpsOfRevenue;

    /// @inheritdoc ILiquidity
    address public regenCollectiveAddress;

    /// @inheritdoc ILiquidity
    address public compContractAddress;

    /// @notice A bool to prevent external eth from being received and locked in the contract
    bool internal _ethTransferable;

    /// @dev The status of sanctions checks. Can be set to false if oracle becomes malicious.
    bool internal _sanctionsPause;

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting storage.
    uint256[500] private __gap;

    /// @notice The initializer for the NiftyApes protocol.
    ///         NiftyApes is intended to be deployed behind a proxy and thus needs to initialize
    ///         its state outside of a constructor.
    function initialize(address newCompContractAddress) public initializer {
        regenCollectiveBpsOfRevenue = 100;
        regenCollectiveAddress = address(0x252de94Ae0F07fb19112297F299f8c9Cc10E28a6);
        compContractAddress = newCompContractAddress;

        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }

    /// @inheritdoc ILiquidityAdmin
    function setCAssetAddress(address asset, address cAsset) external onlyOwner {
        address cAssetOld = assetToCAsset[asset];
        address assetOld = _cAssetToAsset[cAsset];
        if (cAssetOld != address(0)) {
            _cAssetToAsset[cAssetOld] = address(0);
        }
        if (assetOld != address(0)) {
            assetToCAsset[assetOld] = address(0);
        }

        assetToCAsset[asset] = cAsset;
        _cAssetToAsset[cAsset] = asset;

        emit AssetToCAssetSet(asset, cAsset);
    }

    /// @inheritdoc ILiquidityAdmin
    function setMaxCAssetBalance(address cAsset, uint256 maxBalance) external onlyOwner {
        maxBalanceByCAsset[cAsset] = maxBalance;
    }

    /// @inheritdoc ILiquidityAdmin
    function updateLendingContractAddress(address newLendingContractAddress) external onlyOwner {
        emit LiquidityXLendingContractAddressUpdated(
            lendingContractAddress,
            newLendingContractAddress
        );
        lendingContractAddress = newLendingContractAddress;
    }

    /// @inheritdoc ILiquidityAdmin
    function updateRegenCollectiveBpsOfRevenue(uint16 newRegenCollectiveBpsOfRevenue)
        external
        onlyOwner
    {
        require(newRegenCollectiveBpsOfRevenue <= 1_000, "00002");
        require(newRegenCollectiveBpsOfRevenue >= regenCollectiveBpsOfRevenue, "00039");
        emit RegenCollectiveBpsOfRevenueUpdated(
            regenCollectiveBpsOfRevenue,
            newRegenCollectiveBpsOfRevenue
        );
        regenCollectiveBpsOfRevenue = newRegenCollectiveBpsOfRevenue;
    }

    /// @inheritdoc ILiquidityAdmin
    function updateRegenCollectiveAddress(address newRegenCollectiveAddress) external onlyOwner {
        emit RegenCollectiveAddressUpdated(newRegenCollectiveAddress);
        regenCollectiveAddress = newRegenCollectiveAddress;
    }

    /// @inheritdoc ILiquidityAdmin
    function pauseSanctions() external onlyOwner {
        _sanctionsPause = true;
        emit LiquiditySanctionsPaused();
    }

    /// @inheritdoc ILiquidityAdmin
    function unpauseSanctions() external onlyOwner {
        _sanctionsPause = false;
        emit LiquiditySanctionsUnpaused();
    }

    /// @inheritdoc ILiquidityAdmin
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc ILiquidityAdmin
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc ILiquidity
    function getCAssetBalance(address account, address cAsset) public view returns (uint256) {
        return _balanceByAccountByCAsset[account][cAsset];
    }

    /// @inheritdoc ILiquidity
    function getCAsset(address asset) public view returns (address) {
        address cAsset = assetToCAsset[asset];
        require(cAsset != address(0), "00040");
        require(asset == _cAssetToAsset[cAsset], "00042");
        return cAsset;
    }

    function _getAsset(address cAsset) internal view returns (address) {
        address asset = _cAssetToAsset[cAsset];
        require(asset != address(0), "00041");
        require(cAsset == assetToCAsset[asset], "00042");
        return asset;
    }

    /// @inheritdoc ILiquidity
    function supplyErc20(address asset, uint256 tokenAmount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        _requireIsNotSanctioned(msg.sender);

        address cAsset = getCAsset(asset);

        uint256 cTokensMinted = _mintCErc20(msg.sender, asset, tokenAmount);

        _balanceByAccountByCAsset[msg.sender][cAsset] += cTokensMinted;

        _requireMaxCAssetBalance(cAsset);

        emit Erc20Supplied(msg.sender, asset, tokenAmount, cTokensMinted);

        return cTokensMinted;
    }

    /// @inheritdoc ILiquidity
    function supplyCErc20(address cAsset, uint256 cTokenAmount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        _requireIsNotSanctioned(msg.sender);
        _requireAmountGreaterThanZero(cTokenAmount);

        _getAsset(cAsset); // Ensures asset / cAsset is in the allow list
        IERC20Upgradeable cToken = IERC20Upgradeable(cAsset);

        cToken.safeTransferFrom(msg.sender, address(this), cTokenAmount);

        _balanceByAccountByCAsset[msg.sender][cAsset] += cTokenAmount;

        _requireMaxCAssetBalance(cAsset);

        emit CErc20Supplied(msg.sender, cAsset, cTokenAmount);

        return cTokenAmount;
    }

    /// @inheritdoc ILiquidity
    function withdrawErc20(address asset, uint256 tokenAmount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        _requireIsNotSanctioned(msg.sender);

        address cAsset = getCAsset(asset);
        IERC20Upgradeable underlying = IERC20Upgradeable(asset);

        if (msg.sender == owner()) {
            uint256 cTokensBurnt = _ownerWithdrawUnderlying(asset, cAsset);
            return cTokensBurnt;
        } else {
            uint256 cTokensBurnt = _burnCErc20(asset, tokenAmount);

            _withdrawCBalance(msg.sender, cAsset, cTokensBurnt);

            underlying.safeTransfer(msg.sender, tokenAmount);

            emit Erc20Withdrawn(msg.sender, asset, tokenAmount, cTokensBurnt);

            return cTokensBurnt;
        }
    }

    /// @inheritdoc ILiquidity
    function withdrawCErc20(address cAsset, uint256 cTokenAmount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        _requireIsNotSanctioned(msg.sender);

        IERC20Upgradeable cToken = IERC20Upgradeable(cAsset);

        if (msg.sender == owner()) {
            uint256 cTokensBurnt = _ownerWithdrawCToken(cAsset);
            return cTokensBurnt;
        } else {
            _withdrawCBalance(msg.sender, cAsset, cTokenAmount);

            cToken.safeTransfer(msg.sender, cTokenAmount);

            emit CErc20Withdrawn(msg.sender, cAsset, cTokenAmount);

            return cTokenAmount;
        }
    }

    /// @inheritdoc ILiquidity
    function supplyEth() external payable whenNotPaused nonReentrant returns (uint256) {
        _requireIsNotSanctioned(msg.sender);

        address cAsset = getCAsset(ETH_ADDRESS);

        uint256 cTokensMinted = _mintCEth(msg.value);

        _balanceByAccountByCAsset[msg.sender][cAsset] += cTokensMinted;

        _requireMaxCAssetBalance(cAsset);

        emit EthSupplied(msg.sender, msg.value, cTokensMinted);

        return cTokensMinted;
    }

    /// @inheritdoc ILiquidity
    function withdrawEth(uint256 amount) external whenNotPaused nonReentrant returns (uint256) {
        _requireIsNotSanctioned(msg.sender);

        address cAsset = getCAsset(ETH_ADDRESS);

        if (msg.sender == owner()) {
            return _ownerWithdrawUnderlying(ETH_ADDRESS, cAsset);
        } else {
            uint256 cTokensBurnt = _burnCErc20(ETH_ADDRESS, amount);

            _withdrawCBalance(msg.sender, cAsset, cTokensBurnt);

            payable(msg.sender).sendValue(amount);

            emit EthWithdrawn(msg.sender, amount, cTokensBurnt);

            return cTokensBurnt;
        }
    }

    /// @inheritdoc ILiquidity
    function withdrawComp() external whenNotPaused nonReentrant onlyOwner returns (uint256) {
        _requireIsNotSanctioned(msg.sender);

        uint256 ownerBalance = IERC20Upgradeable(compContractAddress).balanceOf(address(this));

        uint256 bpsForRegen = (ownerBalance * regenCollectiveBpsOfRevenue) / 10_000;

        uint256 ownerBalanceMinusRegen = ownerBalance - bpsForRegen;

        _sendValue(compContractAddress, ownerBalanceMinusRegen, owner());

        _sendValue(compContractAddress, bpsForRegen, regenCollectiveAddress);

        emit PercentForRegen(regenCollectiveAddress, compContractAddress, bpsForRegen, 0);

        emit Erc20Withdrawn(owner(), compContractAddress, ownerBalanceMinusRegen, 0);

        return ownerBalance;
    }

    function _requireEthTransferable() internal view {
        require(_ethTransferable, "00043");
    }

    function _requireIsNotSanctioned(address addressToCheck) internal view {
        if (!_sanctionsPause) {
            SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
            bool isToSanctioned = sanctionsList.isSanctioned(addressToCheck);
            require(!isToSanctioned, "00017");
        }
    }

    function _requireMaxCAssetBalance(address cAsset) internal view {
        uint256 maxCAssetBalance = maxBalanceByCAsset[cAsset];

        require(maxCAssetBalance >= ICERC20(cAsset).balanceOf(address(this)), "00044");
    }

    function _requireCAssetBalance(
        address account,
        address cAsset,
        uint256 amount
    ) internal view {
        require(getCAssetBalance(account, cAsset) >= amount, "00034");
    }

    function _requireAmountGreaterThanZero(uint256 amount) internal pure {
        require(amount > 0, "00045");
    }

    function _requireLendingContract() internal view {
        require(msg.sender == lendingContractAddress, "00031");
    }

    function _ownerWithdrawUnderlying(address asset, address cAsset)
        internal
        returns (uint256 cTokensBurnt)
    {
        uint256 ownerBalance = getCAssetBalance(owner(), cAsset);

        uint256 ownerBalanceUnderlying = cAssetAmountToAssetAmount(cAsset, ownerBalance);

        cTokensBurnt = _burnCErc20(asset, ownerBalanceUnderlying);

        uint256 bpsForRegen = (cTokensBurnt * regenCollectiveBpsOfRevenue) / 10_000;

        uint256 ownerBalanceMinusRegen = cTokensBurnt - bpsForRegen;

        uint256 ownerAmountUnderlying = cAssetAmountToAssetAmount(cAsset, ownerBalanceMinusRegen);

        uint256 regenAmountUnderlying = cAssetAmountToAssetAmount(cAsset, bpsForRegen);

        _withdrawCBalance(owner(), cAsset, cTokensBurnt);

        _sendValue(asset, ownerAmountUnderlying, owner());

        _sendValue(asset, regenAmountUnderlying, regenCollectiveAddress);

        emit PercentForRegen(regenCollectiveAddress, asset, regenAmountUnderlying, bpsForRegen);

        if (asset == ETH_ADDRESS) {
            emit EthWithdrawn(owner(), ownerAmountUnderlying, ownerBalanceMinusRegen);
        } else {
            emit Erc20Withdrawn(owner(), asset, ownerAmountUnderlying, ownerBalanceMinusRegen);
        }
    }

    function _ownerWithdrawCToken(address cAsset) internal returns (uint256) {
        uint256 ownerBalance = getCAssetBalance(owner(), cAsset);

        uint256 bpsForRegen = (ownerBalance * regenCollectiveBpsOfRevenue) / 10_000;

        uint256 ownerBalanceMinusRegen = ownerBalance - bpsForRegen;

        _withdrawCBalance(owner(), cAsset, ownerBalance);

        _sendValue(cAsset, ownerBalanceMinusRegen, owner());

        _sendValue(cAsset, bpsForRegen, regenCollectiveAddress);

        uint256 regenAmountUnderlying = cAssetAmountToAssetAmount(cAsset, bpsForRegen);

        emit PercentForRegen(regenCollectiveAddress, cAsset, regenAmountUnderlying, bpsForRegen);

        emit CErc20Withdrawn(owner(), cAsset, ownerBalanceMinusRegen);

        return ownerBalance;
    }

    function sendValue(
        address asset,
        uint256 amount,
        address to
    ) external {
        _requireLendingContract();
        _sendValue(asset, amount, to);
    }

    function _sendValue(
        address asset,
        uint256 amount,
        address to
    ) internal {
        _requireAmountGreaterThanZero(amount);
        if (asset == ETH_ADDRESS) {
            payable(to).sendValue(amount);
        } else {
            IERC20Upgradeable(asset).safeTransfer(to, amount);
        }
    }

    /// @inheritdoc ILiquidity
    function mintCErc20(
        address from,
        address asset,
        uint256 amount
    ) external returns (uint256) {
        _requireLendingContract();
        return _mintCErc20(from, asset, amount);
    }

    function _mintCErc20(
        address from,
        address asset,
        uint256 amount
    ) internal returns (uint256) {
        _requireAmountGreaterThanZero(amount);

        address cAsset = assetToCAsset[asset];
        IERC20Upgradeable underlying = IERC20Upgradeable(asset);
        ICERC20 cToken = ICERC20(cAsset);
        underlying.safeTransferFrom(from, address(this), amount);

        uint256 allowance = underlying.allowance(address(this), address(cToken));
        if (allowance > 0) {
            underlying.safeDecreaseAllowance(cAsset, allowance);
        }
        underlying.safeIncreaseAllowance(cAsset, amount);

        uint256 cTokenBalanceBefore = cToken.balanceOf(address(this));
        require(cToken.mint(amount) == 0, "00037");
        uint256 cTokenBalanceAfter = cToken.balanceOf(address(this));
        return cTokenBalanceAfter - cTokenBalanceBefore;
    }

    /// @inheritdoc ILiquidity
    function mintCEth() external payable returns (uint256) {
        _requireLendingContract();
        return _mintCEth(msg.value);
    }

    function _mintCEth(uint256 amount) internal returns (uint256) {
        _requireAmountGreaterThanZero(amount);

        address cAsset = assetToCAsset[ETH_ADDRESS];
        ICEther cToken = ICEther(cAsset);
        uint256 cTokenBalanceBefore = cToken.balanceOf(address(this));
        cToken.mint{ value: amount }();
        uint256 cTokenBalanceAfter = cToken.balanceOf(address(this));
        return cTokenBalanceAfter - cTokenBalanceBefore;
    }

    /// @inheritdoc ILiquidity
    function burnCErc20(address asset, uint256 amount) external returns (uint256) {
        _requireLendingContract();
        return _burnCErc20(asset, amount);
    }

    // @notice param amount is denominated in the underlying asset, not cAsset
    function _burnCErc20(address asset, uint256 amount) internal returns (uint256) {
        _requireAmountGreaterThanZero(amount);

        address cAsset = assetToCAsset[asset];
        ICERC20 cToken = ICERC20(cAsset);

        uint256 cTokenBalanceBefore = cToken.balanceOf(address(this));
        _ethTransferable = true;
        require(cToken.redeemUnderlying(amount) == 0, "00038");
        _ethTransferable = false;
        uint256 cTokenBalanceAfter = cToken.balanceOf(address(this));
        return cTokenBalanceBefore - cTokenBalanceAfter;
    }

    /// @inheritdoc ILiquidity
    function withdrawCBalance(
        address account,
        address cAsset,
        uint256 cTokenAmount
    ) external {
        _requireLendingContract();
        _withdrawCBalance(account, cAsset, cTokenAmount);
    }

    function _withdrawCBalance(
        address account,
        address cAsset,
        uint256 cTokenAmount
    ) internal {
        _requireCAssetBalance(account, cAsset, cTokenAmount);
        _balanceByAccountByCAsset[account][cAsset] -= cTokenAmount;
    }

    /// @inheritdoc ILiquidity
    function addToCAssetBalance(
        address account,
        address cAsset,
        uint256 amount
    ) external {
        _requireLendingContract();
        _balanceByAccountByCAsset[account][cAsset] += amount;
    }

    /// @inheritdoc ILiquidity
    function assetAmountToCAssetAmount(address asset, uint256 amount) external returns (uint256) {
        address cAsset = assetToCAsset[asset];
        ICERC20 cToken = ICERC20(cAsset);

        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        return Math.divScalarByExpTruncate(amount, exchangeRateMantissa);
    }

    /// @inheritdoc ILiquidity
    function cAssetAmountToAssetAmount(address cAsset, uint256 amount) public returns (uint256) {
        ICERC20 cToken = ICERC20(cAsset);

        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        return Math.mulScalarTruncate(amount, exchangeRateMantissa);
    }

    // solhint-disable-next-line no-empty-blocks
    function renounceOwnership() public override onlyOwner {}

    // This is needed to receive ETH when calling withdrawing ETH from compound
    receive() external payable {
        _requireEthTransferable();
    }
}
