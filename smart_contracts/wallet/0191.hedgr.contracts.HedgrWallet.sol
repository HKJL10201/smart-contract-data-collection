pragma solidity 0.5.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interface/IAddressResolver.sol";
import "./interface/IAddressesProvider.sol";
import "./interface/ISynthetix.sol";
import "./interface/IKyberNetworkProxy.sol";
import "./interface/ILendingPool.sol";
import "./interface/IHedgrWalletFactory.sol";


contract HedgrWallet {
    using SafeMath for uint256;

    // kovan
    ILendingPoolAddressesProvider aaveProvider = ILendingPoolAddressesProvider(
        0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5
    );
    IAddressResolver addressResolver = IAddressResolver(
        0xee38902aFDA193c8d4EDA7F0216f645AD9350402
    );
    IKyberNetworkProxy kyberProxy = IKyberNetworkProxy(
        0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D
    );

    bytes32 synthetixName = "Synthetix";

    address susdAddress = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address snxAddress = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address aEthAddress = 0xD483B49F2d55D2c53D32bE6efF735cB001880F79;

    address factory;

    uint MAX_UINT = 2**256 - 1;

    constructor(address _factory) public {
       factory = _factory;
       IERC20(susdAddress).approve(address(kyberProxy), MAX_UINT);
    }

    event Staked(uint susdIssued, uint ethBal);
    event Hedged(uint aEthBal);

    // Aave
    uint16 referral = 0;
    uint256 variableRate = 2;
    bytes32 susd = "sUSD";

    modifier onlyWalletOwner {
        require(msg.sender == IHedgrWalletFactory(factory).getWalletUser(address(this)));
        _;
    }

    function stakeAndAllocate() public onlyWalletOwner {
        ISynthetix(addressResolver.getAddress(synthetixName)).issueMaxSynths();
        uint susdBal = getSusdBalance();

        kyberProxy.swapTokenToEther(ERC20(susdAddress), susdBal, 0);
        uint ethBal = getEthBalance();

        emit Staked(susdBal, ethBal);
    }

    function hedgeWithLeverage() public onlyWalletOwner {
        uint256 ethBal = address(this).balance;

        ILendingPool lendingPool = ILendingPool(aaveProvider.getLendingPool());
        lendingPool.deposit.value(ethBal)(ethAddress, ethBal, referral);
        lendingPool.setUserUseReserveAsCollateral(ethAddress, true);

        // borrow 67% of deposit
        lendingPool.borrow(ethAddress, ethBal.mul(2).div(3), variableRate, referral);

        emit Hedged(getAEthBalance());
    }

    function getSusdBalance() public view returns (uint256) {
        return IERC20(susdAddress).balanceOf(address(this));
    }

    function getSnxBalance() public view returns (uint256) {
        return IERC20(snxAddress).balanceOf(address(this));
    }

    function getEthBalance() public view returns(uint){
        return address(this).balance;
    }

    function getAEthBalance() public view returns(uint){
        return IERC20(aEthAddress).balanceOf(address(this));
    }

    function getSynthDebt() public view returns(uint){
        return ISynthetix(addressResolver.getAddress(synthetixName)).debtBalanceOf(address(this), susd);
    }

    function() external payable {}
}
