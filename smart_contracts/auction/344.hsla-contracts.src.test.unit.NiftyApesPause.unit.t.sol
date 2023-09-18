// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../../interfaces/compound/ICERC20.sol";
import "../../interfaces/compound/ICEther.sol";
import "../../Lending.sol";
import "../../Liquidity.sol";
import "../../Offers.sol";
import "../../SigLending.sol";
import "../../interfaces/niftyapes/lending/ILendingStructs.sol";
import "../../interfaces/niftyapes/offers/IOffersStructs.sol";

import "../common/BaseTest.sol";
import "../mock/CERC20Mock.sol";
import "../mock/CEtherMock.sol";
import "../mock/ERC20Mock.sol";
import "../mock/ERC721Mock.sol";

import "@openzeppelin-norm/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin-norm/contracts/proxy/transparent/ProxyAdmin.sol";

import "../../interfaces/niftyapes/lending/ILending.sol";
import "../../interfaces/niftyapes/offers/IOffers.sol";
import "../../interfaces/niftyapes/liquidity/ILiquidity.sol";
import "../../interfaces/niftyapes/sigLending/ISigLending.sol";

contract NiftyApesPauseUnitTest is
    BaseTest,
    ILendingStructs,
    IOffersStructs,
    ERC721HolderUpgradeable
{
    ERC20Mock daiToken;
    CERC20Mock cDAIToken;
    CEtherMock cEtherToken;

    NiftyApesLending lendingImplementation;
    NiftyApesOffers offersImplementation;
    NiftyApesLiquidity liquidityImplementation;
    NiftyApesSigLending sigLendingImplementation;

    ProxyAdmin lendingProxyAdmin;
    ProxyAdmin offersProxyAdmin;
    ProxyAdmin liquidityProxyAdmin;
    ProxyAdmin sigLendingProxyAdmin;

    TransparentUpgradeableProxy lendingProxy;
    TransparentUpgradeableProxy offersProxy;
    TransparentUpgradeableProxy liquidityProxy;
    TransparentUpgradeableProxy sigLendingProxy;

    ILending lendingAuction;
    IOffers offersContract;
    ILiquidity liquidityProviders;
    ISigLending sigLendingAuction;

    address compContractAddress = 0xbbEB7c67fa3cfb40069D19E598713239497A3CA5;

    ERC721Mock mockNft;

    bool acceptEth;

    address constant ZERO_ADDRESS = address(0);
    address constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address constant LENDER_1 = address(0x1010);
    address constant LENDER_2 = address(0x2020);
    address constant BORROWER_1 = address(0x101);

    receive() external payable {
        require(acceptEth, "acceptEth");
    }

    function setUp() public {
        liquidityImplementation = new NiftyApesLiquidity();
        offersImplementation = new NiftyApesOffers();
        sigLendingImplementation = new NiftyApesSigLending();
        lendingImplementation = new NiftyApesLending();

        // deploy proxy admins
        lendingProxyAdmin = new ProxyAdmin();
        offersProxyAdmin = new ProxyAdmin();
        liquidityProxyAdmin = new ProxyAdmin();
        sigLendingProxyAdmin = new ProxyAdmin();

        // deploy proxies
        lendingProxy = new TransparentUpgradeableProxy(
            address(lendingImplementation),
            address(lendingProxyAdmin),
            bytes("")
        );
        offersProxy = new TransparentUpgradeableProxy(
            address(offersImplementation),
            address(offersProxyAdmin),
            bytes("")
        );
        liquidityProxy = new TransparentUpgradeableProxy(
            address(liquidityImplementation),
            address(liquidityProxyAdmin),
            bytes("")
        );

        sigLendingProxy = new TransparentUpgradeableProxy(
            address(sigLendingImplementation),
            address(sigLendingProxyAdmin),
            bytes("")
        );

        // declare interfaces
        lendingAuction = ILending(address(lendingProxy));
        liquidityProviders = ILiquidity(address(liquidityProxy));
        offersContract = IOffers(address(offersProxy));
        sigLendingAuction = ISigLending(address(sigLendingProxy));

        // initialize proxies
        liquidityProviders.initialize(address(compContractAddress));
        offersContract.initialize(address(liquidityProviders));
        sigLendingAuction.initialize(address(offersContract));
        lendingAuction.initialize(
            address(liquidityProviders),
            address(offersContract),
            address(sigLendingAuction)
        );

        offersContract.updateLendingContractAddress(address(lendingAuction));

        daiToken = new ERC20Mock();
        daiToken.initialize("USD Coin", "DAI");
        cDAIToken = new CERC20Mock();
        cDAIToken.initialize(daiToken);
        liquidityProviders.setCAssetAddress(address(daiToken), address(cDAIToken));

        cEtherToken = new CEtherMock();
        cEtherToken.initialize();
        liquidityProviders.setCAssetAddress(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            address(cEtherToken)
        );

        lendingAuction.pause();
        liquidityProviders.pause();
        offersContract.pause();
        sigLendingAuction.pause();

        acceptEth = true;

        mockNft = new ERC721Mock();
        mockNft.initialize("BoredApe", "BAYC");

        mockNft.safeMint(address(this), 1);
        mockNft.approve(address(lendingAuction), 1);

        mockNft.safeMint(address(this), 2);
        mockNft.approve(address(lendingAuction), 2);
    }

    function getOffer() internal view returns (Offer memory offer) {
        return
            Offer({
                creator: address(0x0000000000000000000000000000000000000001),
                nftContractAddress: address(0x0000000000000000000000000000000000000002),
                interestRatePerSecond: 3,
                fixedTerms: false,
                floorTerm: false,
                lenderOffer: true,
                nftId: 4,
                asset: address(daiToken),
                amount: 6,
                duration: 7,
                expiration: 8,
                floorTermLimit: 1
            });
    }

    function testCannotPause_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        lendingAuction.pause();
    }

    function testCannotUnpause_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        lendingAuction.unpause();
    }

    function testCannotPauseLiquidityProviders_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        liquidityProviders.pause();
    }

    function testCannotUnpauseLiquidityProviders_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        liquidityProviders.unpause();
    }

    function testCannotPauseOffersContract_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        offersContract.pause();
    }

    function testCannotUnpauseOffersContract_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        offersContract.unpause();
    }

    function testCannotPauseSigLendingAuction_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        sigLendingAuction.pause();
    }

    function testCannotUnpauseSigLendingAuction_not_owner() public {
        hevm.startPrank(LENDER_1);

        hevm.expectRevert("Ownable: caller is not the owner");

        sigLendingAuction.unpause();
    }

    function testCannotSupplyErc20_paused() public {
        hevm.expectRevert("Pausable: paused");

        liquidityProviders.supplyErc20(address(daiToken), 1);
    }

    function testCannotSupplyCErc20_paused() public {
        hevm.expectRevert("Pausable: paused");

        liquidityProviders.supplyCErc20(address(cDAIToken), 1);
    }

    function testCannotWithdrawErc20_paused() public {
        hevm.expectRevert("Pausable: paused");

        liquidityProviders.withdrawErc20(address(daiToken), 1);
    }

    function testCannotwithdrawCErc20_paused() public {
        hevm.expectRevert("Pausable: paused");

        liquidityProviders.withdrawCErc20(address(cDAIToken), 1);
    }

    function testCannotSupplyEth_paused() public {
        hevm.expectRevert("Pausable: paused");

        liquidityProviders.supplyEth();
    }

    function testCannotWithdrawEth_paused() public {
        hevm.expectRevert("Pausable: paused");

        liquidityProviders.withdrawEth(1);
    }

    function testCannotExecuteLoanByBorrower_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.executeLoanByBorrower(address(0), 1, bytes32(0), false);
    }

    function testCannotExecuteLoanByBorrowerSignature_paused() public {
        hevm.expectRevert("Pausable: paused");

        sigLendingAuction.executeLoanByBorrowerSignature(getOffer(), "", 0);
    }

    function testCannotExecuteLoanByLender_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.executeLoanByLender(address(0), 1, bytes32(0), false);
    }

    function testCannotExecuteLoanByLenderSignature_paused() public {
        hevm.expectRevert("Pausable: paused");

        sigLendingAuction.executeLoanByLenderSignature(getOffer(), "");
    }

    function testCannotRefinanceByBorrower_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.refinanceByBorrower(
            address(0),
            1,
            false,
            bytes32(0),
            uint32(block.timestamp)
        );
    }

    function testCannotRefinanceByBorrowerSignature_paused() public {
        hevm.expectRevert("Pausable: paused");

        sigLendingAuction.refinanceByBorrowerSignature(getOffer(), "", 1, uint32(block.timestamp));
    }

    function testCannotRefinanceByLender_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.refinanceByLender(getOffer(), 0);
    }

    function testCannotDrawLoanAmount_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.drawLoanAmount(address(0), 1, 2);
    }

    function testCannotRepayLoan_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.repayLoan(address(0), 1);
    }

    function testCannotRepayLoanForAccount_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.repayLoanForAccount(address(0), 1, uint32(block.timestamp));
    }

    function testCannotPartialRepayLoan_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.partialRepayLoan(address(0), 1, 2);
    }

    function testCannotSeizeAsset_paused() public {
        hevm.expectRevert("Pausable: paused");

        lendingAuction.seizeAsset(address(0), 1);
    }
}
