pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./CaseToken.sol";
import "./CaseReward.sol";

contract CaseStaking {
    using SafeMath for uint256;
    using SafeERC20 for CaseToken;

    event CreateStake(
        uint256 idx,
        address user,
        address referrer,
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        uint256 interestAmount
    );
    event ReceiveStakeReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawReward(uint256 idx, address user, uint256 rewardAmount);
    event WithdrawStake(uint256 idx, address user);

    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant CASE_PRECISION = 10**8;
    uint256 internal constant INTEREST_SLOPE = 2 * (10**8);
    uint256 internal constant BIGGER_BONUS_DIVISOR = 10**15; // biggerBonus = stakeAmount / (10 million case)
    uint256 internal constant MAX_BIGGER_BONUS = 10**17; // biggerBonus <= 10%
    uint256 internal constant DAILY_BASE_REWARD = 15 * (10**14); // dailyBaseReward = 0.0015
    uint256 internal constant DAILY_GROWING_REWARD = 10**12; // dailyGrowingReward = 1e-6
    uint256 internal constant MAX_STAKE_PERIOD = 1000; // Max staking time is 1000 days
    uint256 internal constant MIN_STAKE_PERIOD = 30; // Min staking time is 30 days
    uint256 internal constant DAY_IN_SECONDS = 86400;
    uint256 internal constant COMMISSION_RATE = 20 * (10**16); // 20%
    uint256 internal constant REFERRAL_STAKER_BONUS = 3 * (10**16); // 3%
    uint256 internal constant YEAR_IN_DAYS = 365;
    uint256 public constant CASE_MINT_CAP = 240240000 * CASE_PRECISION; // 240.24 million CASE

    struct Stake {
        address staker;
        uint256 stakeAmount;
        uint256 interestAmount;
        uint256 withdrawnInterestAmount;
        uint256 stakeTimestamp;
        uint256 stakeTimeInDays;
        bool active;
    }
    Stake[] public stakeList;
    mapping(address => uint256) public userStakeAmount;
    uint256 public mintedCaseTokens;
    bool public initialized;

    CaseToken public caseToken;
    CaseReward public caseReward;

    constructor(address _caseToken) public {
        caseToken = CaseToken(_caseToken);
    }

    function init(address _caseReward) public {
        require(!initialized, "CaseStaking: Already initialized");
        initialized = true;

        caseReward = CaseReward(_caseReward);
    }

    function stake(
        uint256 stakeAmount,
        uint256 stakeTimeInDays,
        address referrer
    ) public returns (uint256 stakeIdx) {
        require(
            stakeTimeInDays >= MIN_STAKE_PERIOD,
            "CaseStaking: stakeTimeInDays < MIN_STAKE_PERIOD"
        );
        require(
            stakeTimeInDays <= MAX_STAKE_PERIOD,
            "CaseStaking: stakeTimeInDays > MAX_STAKE_PERIOD"
        );

        // record stake
        uint256 interestAmount = getInterestAmount(
            stakeAmount,
            stakeTimeInDays
        );
        stakeIdx = stakeList.length;
        stakeList.push(
            Stake({
                staker: msg.sender,
                stakeAmount: stakeAmount,
                interestAmount: interestAmount,
                withdrawnInterestAmount: 0,
                stakeTimestamp: now,
                stakeTimeInDays: stakeTimeInDays,
                active: true
            })
        );
        mintedCaseTokens = mintedCaseTokens.add(interestAmount);
        userStakeAmount[msg.sender] = userStakeAmount[msg.sender].add(
            stakeAmount
        );

        // transfer CASE from msg.sender
        caseToken.safeTransferFrom(msg.sender, address(this), stakeAmount);

        // mint CASE interest
        caseToken.mint(address(this), interestAmount);

        // handle referral
        if (caseReward.canRefer(msg.sender, referrer)) {
            caseReward.refer(msg.sender, referrer);
        }
        address actualReferrer = caseReward.referrerOf(msg.sender);
        if (actualReferrer != address(0)) {
            // pay referral bonus to referrer
            uint256 rawCommission = interestAmount.mul(COMMISSION_RATE).div(
                PRECISION
            );
            caseToken.mint(address(this), rawCommission);
            caseToken.safeApprove(address(caseReward), rawCommission);
            uint256 leftoverAmount = caseReward.payCommission(
                actualReferrer,
                msg.sender,
                address(caseToken),
                rawCommission,
                true
            );
            caseToken.burn(leftoverAmount);

            // pay referral bonus to staker
            uint256 referralStakerBonus = interestAmount
            .mul(REFERRAL_STAKER_BONUS)
            .div(PRECISION);
            caseToken.mint(msg.sender, referralStakerBonus);

            mintedCaseTokens = mintedCaseTokens.add(
                rawCommission.sub(leftoverAmount).add(referralStakerBonus)
            );

            emit ReceiveStakeReward(stakeIdx, msg.sender, referralStakerBonus);
        }

        require(mintedCaseTokens <= CASE_MINT_CAP, "CaseStaking: reached cap");

        emit CreateStake(
            stakeIdx,
            msg.sender,
            actualReferrer,
            stakeAmount,
            stakeTimeInDays,
            interestAmount
        );
    }

    function withdraw(uint256 stakeIdx) public {
        Stake storage stakeObj = stakeList[stakeIdx];
        require(
            stakeObj.staker == msg.sender,
            "CaseStaking: Sender not staker"
        );
        require(stakeObj.active, "CaseStaking: Not active");

        // calculate amount that can be withdrawn
        uint256 stakeTimeInSeconds = stakeObj.stakeTimeInDays.mul(
            DAY_IN_SECONDS
        );
        uint256 withdrawAmount;
        if (now >= stakeObj.stakeTimestamp.add(stakeTimeInSeconds)) {
            // matured, withdraw all
            withdrawAmount = stakeObj
            .stakeAmount
            .add(stakeObj.interestAmount)
            .sub(stakeObj.withdrawnInterestAmount);
            stakeObj.active = false;
            stakeObj.withdrawnInterestAmount = stakeObj.interestAmount;
            userStakeAmount[msg.sender] = userStakeAmount[msg.sender].sub(
                stakeObj.stakeAmount
            );

            emit WithdrawReward(
                stakeIdx,
                msg.sender,
                stakeObj.interestAmount.sub(stakeObj.withdrawnInterestAmount)
            );
            emit WithdrawStake(stakeIdx, msg.sender);
        } else {
            // not mature, partial withdraw
            withdrawAmount = stakeObj
            .interestAmount
            .mul(uint256(now).sub(stakeObj.stakeTimestamp))
            .div(stakeTimeInSeconds)
            .sub(stakeObj.withdrawnInterestAmount);

            // record withdrawal
            stakeObj.withdrawnInterestAmount = stakeObj
            .withdrawnInterestAmount
            .add(withdrawAmount);

            emit WithdrawReward(stakeIdx, msg.sender, withdrawAmount);
        }

        // withdraw interest to sender
        caseToken.safeTransfer(msg.sender, withdrawAmount);
    }

    function getInterestAmount(uint256 stakeAmount, uint256 stakeTimeInDays)
        public
        view
        returns (uint256)
    {
        uint256 earlyFactor = _earlyFactor(mintedCaseTokens);
        uint256 biggerBonus = stakeAmount.mul(PRECISION).div(
            BIGGER_BONUS_DIVISOR
        );
        if (biggerBonus > MAX_BIGGER_BONUS) {
            biggerBonus = MAX_BIGGER_BONUS;
        }

        // convert yearly bigger bonus to stake time
        biggerBonus = biggerBonus.mul(stakeTimeInDays).div(YEAR_IN_DAYS);

        uint256 longerBonus = _longerBonus(stakeTimeInDays);
        uint256 interestRate = biggerBonus
        .add(longerBonus)
        .mul(earlyFactor)
        .div(PRECISION);
        uint256 interestAmount = stakeAmount.mul(interestRate).div(PRECISION);
        return interestAmount;
    }

    function _longerBonus(uint256 stakeTimeInDays)
        internal
        pure
        returns (uint256)
    {
        return
            DAILY_BASE_REWARD.mul(stakeTimeInDays).add(
                DAILY_GROWING_REWARD
                    .mul(stakeTimeInDays)
                    .mul(stakeTimeInDays.add(1))
                    .div(2)
            );
    }

    function _earlyFactor(uint256 _mintedCaseTokens)
        internal
        pure
        returns (uint256)
    {
        uint256 tmp = INTEREST_SLOPE.mul(_mintedCaseTokens).div(CASE_PRECISION);
        if (tmp > PRECISION) {
            return 0;
        }
        return PRECISION.sub(tmp);
    }
}
