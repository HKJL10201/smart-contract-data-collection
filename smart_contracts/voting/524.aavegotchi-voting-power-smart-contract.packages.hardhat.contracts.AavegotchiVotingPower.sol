pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
}

interface IWAPGHST {
  function balanceOf(address account) external view returns (uint256);
  function convertToAssets(uint256 shares) external view returns (uint256);
}

struct StakingUserInfo {
    address lpToken;
    uint256 allocPoint;
    uint256 pending;
    uint256 userBalance;
    uint256 poolBalance;
}

interface IGLTRStaking {
    function allUserInfo(address _user) external view returns (StakingUserInfo[] memory _info);
}

struct AGIP37Info {
    uint256 amGHSTBalance;
    uint256[2] unstakedWapGHST;
    uint256[2] stakedWapGHST;
    uint256 stakedGHSTFUDInfo;
    uint256 stakedGHSTFOMOInfo;
    uint256 stakedGHSTALPHAInfo;
    uint256 stakedGHSTKEKInfo;
    uint256 stakedGHSTUSDCInfo;
    uint256 stakedGHSTWMATICInfo;
    uint256 stakedGHSTGLTRInfo;
    uint256 unstakedGHSTFUDInfo;
    uint256 unstakedGHSTFOMOInfo;
    uint256 unstakedGHSTALPHAInfo;
    uint256 unstakedGHSTKEKInfo;
    uint256 unstakedGHSTGLTRInfo;
}

struct LPTokensInfo {
    uint256[2] GHSTFUDLPInfo;
    uint256[2] GHSTFOMOLPInfo;
    uint256[2] GHSTALPHALPInfo;
    uint256[2] GHSTKEKLPInfo;
    uint256[2] GHSTUSDCLPInfo;
    uint256[2] GHSTWMATICLPInfo;
    uint256[2] GHSTGLTRLPInfo;
}

contract AavegotchiVotingPower {
    address public GHST_TOKEN = address(0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7);

    address public GHST_FUD_UNI_TOKEN = address(0xfEC232CC6F0F3aEb2f81B2787A9bc9F6fc72EA5C);
    address public GHST_FOMO_UNI_TOKEN = address(0x641CA8d96b01Db1E14a5fBa16bc1e5e508A45f2B);
    address public GHST_ALPHA_UNI_TOKEN = address(0xC765ECA0Ad3fd27779d36d18E32552Bd7e26Fd7b);
    address public GHST_KEK_UNI_TOKEN = address(0xBFad162775EBfB9988db3F24ef28CA6Bc2fB92f0);
    address public GHST_USDC_UNI_TOKEN = address(0x096C5CCb33cFc5732Bcd1f3195C13dBeFC4c82f4);
    address public GHST_WMATIC_UNI_TOKEN = address(0xf69e93771F11AECd8E554aA165C3Fe7fd811530c);
    address public GHST_GLTR_UNI_TOKEN = address(0xb0E35478a389dD20050D66a67FB761678af99678);

    address public GLTR_STAKING = address(0x1fE64677Ab1397e20A1211AFae2758570fEa1B8c);
    uint public GLTR_POOL_ID_WAPGHST = 0;
    uint public GHST_FUD_LP_POOL_ID = 1;
    uint public GHST_FOMO_LP_POOL_ID = 2;
    uint public GHST_ALPHA_LP_POOL_ID = 3;
    uint public GHST_KEK_LP_POOL_ID = 4;
    uint public GHST_USDC_LP_POOL_ID = 5;
    uint public GHST_WMATIC_LP_POOL_ID = 6;
    uint public GHST_GLTR_LP_POOL_ID = 7;
    
    address public AM_GHST_TOKEN = address(0x080b5BF8f360F624628E0fb961F4e67c9e3c7CF1);
    
    address public WAP_GHST_TOKEN = address(0x73958d46B7aA2bc94926d8a215Fa560A5CdCA3eA);

    function amGHSTVotingPower(address _account) public view returns (uint256) {
        uint256 amGHSTVP = IERC20(AM_GHST_TOKEN).balanceOf(_account);
        return amGHSTVP;
    }

    function unstakedWAPGHSTVotingPower(address _account) public view returns (uint256[2] memory) {
        uint256 unstakedWAPGHSTBalance = IWAPGHST(WAP_GHST_TOKEN).balanceOf(_account);
        uint256 convertedUnstakedWAPGHST = IWAPGHST(WAP_GHST_TOKEN).convertToAssets(unstakedWAPGHSTBalance);

        uint256[2] memory parts = [
            unstakedWAPGHSTBalance,
            convertedUnstakedWAPGHST
        ];

        return parts;
    }

    function gltrStakedWAPGHSTVotingPower(address _account) public view returns (uint256[2] memory) {
        uint256 stakedWAPGHSTBalance = IGLTRStaking(GLTR_STAKING).allUserInfo(_account)[GLTR_POOL_ID_WAPGHST].userBalance;
        uint256 convertedStakedWAPGHST = IWAPGHST(WAP_GHST_TOKEN).convertToAssets(stakedWAPGHSTBalance);

        uint256[2] memory parts = [
            stakedWAPGHSTBalance,
            convertedStakedWAPGHST
        ];

        return parts;
    }

    function gltrStakedLPTokenVotingPower(address _account, uint poolId) public view returns (uint256) {
        uint256 stakedLPTokenBalance = IGLTRStaking(GLTR_STAKING).allUserInfo(_account)[poolId].userBalance;
        return stakedLPTokenBalance;
    }

    function unstakedLPTokenVotingPower(address _account, address _lpToken) public view returns (uint256) {
        uint256 unstakedLPTokenBalance = IERC20(_lpToken).balanceOf(_account);
        return unstakedLPTokenBalance;
    }

    function agip37VotingPower(address _account) public view returns (AGIP37Info memory) {
        AGIP37Info memory votingInfo = AGIP37Info(
            amGHSTVotingPower(_account),

            unstakedWAPGHSTVotingPower(_account),
            gltrStakedWAPGHSTVotingPower(_account),
            
            gltrStakedLPTokenVotingPower(_account, GHST_FUD_LP_POOL_ID),
            gltrStakedLPTokenVotingPower(_account, GHST_FOMO_LP_POOL_ID),
            gltrStakedLPTokenVotingPower(_account, GHST_ALPHA_LP_POOL_ID),
            gltrStakedLPTokenVotingPower(_account, GHST_KEK_LP_POOL_ID),
            gltrStakedLPTokenVotingPower(_account, GHST_USDC_LP_POOL_ID),
            gltrStakedLPTokenVotingPower(_account, GHST_WMATIC_LP_POOL_ID),
            gltrStakedLPTokenVotingPower(_account, GHST_GLTR_LP_POOL_ID),
            
            unstakedLPTokenVotingPower(_account, GHST_FUD_UNI_TOKEN),
            unstakedLPTokenVotingPower(_account, GHST_FOMO_UNI_TOKEN),
            unstakedLPTokenVotingPower(_account, GHST_ALPHA_UNI_TOKEN),
            unstakedLPTokenVotingPower(_account, GHST_KEK_UNI_TOKEN),
            unstakedLPTokenVotingPower(_account, GHST_GLTR_UNI_TOKEN)
        );

        return votingInfo;
    }

    function lpTokensInfo() public view returns (LPTokensInfo memory) {
        uint256[2] memory fud = [ IERC20(GHST_FUD_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_FUD_UNI_TOKEN) ];
        uint256[2] memory fomo = [ IERC20(GHST_FOMO_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_FOMO_UNI_TOKEN) ];
        uint256[2] memory alpha = [ IERC20(GHST_ALPHA_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_ALPHA_UNI_TOKEN) ];
        uint256[2] memory kek = [ IERC20(GHST_KEK_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_KEK_UNI_TOKEN) ];
        uint256[2] memory usdc = [ IERC20(GHST_USDC_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_USDC_UNI_TOKEN) ];
        uint256[2] memory wmatic = [ IERC20(GHST_WMATIC_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_WMATIC_UNI_TOKEN) ];
        uint256[2] memory gltr = [ IERC20(GHST_GLTR_UNI_TOKEN).totalSupply(), IERC20(GHST_TOKEN).balanceOf(GHST_GLTR_UNI_TOKEN) ];

        LPTokensInfo memory lpTokenInfo = LPTokensInfo(
            fud,
            fomo,
            alpha,
            kek,
            usdc,
            wmatic,
            gltr
        );

        return lpTokenInfo;
    }
}