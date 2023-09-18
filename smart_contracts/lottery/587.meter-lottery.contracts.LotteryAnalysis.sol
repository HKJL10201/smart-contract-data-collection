// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

interface ILottery {
    function getUserInfo(address) external view returns (uint256[] memory);

    function getRewardView(uint256 _tokenId) external view returns (uint256);

    function lotteryNFT() external view returns (address);
}

interface INFT {
    function issueIndex(uint256) external view returns (uint256);

    function getLotteryNumbers(uint256 tokenId) external view returns (uint8[4] memory);

    function getLotteryIssueIndex(uint256 tokenId) external view returns (uint256);

    function getClaimStatus(uint256 tokenId) external view returns (bool);
}

contract LotteryAnalysis {
    address public constant Lottery_HUSD = 0xD3116F70DaC6e1D9c50763026b1CcF560e4664D4;
    address public constant Lottery_GOC = 0x822542e0b599Fd512AC91E44AB6b3E5098345693;

    /**
     * @dev Get all NFTs of the user
     * @param _user user address
     * @return _tickets NFT Token ID
     * @return _issueIndex release index
     * @return _claimed Whether to claim the prize
     * @return _reward bonus
     */
    function getUserGOCTickets(address _user)
        public
        view
        returns (
            uint256[] memory _tickets,
            uint256[] memory _issueIndex,
            bool[] memory _claimed,
            uint256[] memory _reward
        )
    {
        _tickets = ILottery(Lottery_GOC).getUserInfo(_user);
        _issueIndex = new uint256[](_tickets.length);
        _claimed = new bool[](_tickets.length);
        _reward = new uint256[](_tickets.length);
        address NFT_GOC = ILottery(Lottery_GOC).lotteryNFT();
        for (uint256 i = 0; i < _tickets.length; i++) {
            _issueIndex[i] = INFT(NFT_GOC).getLotteryIssueIndex(_tickets[i]);
            _claimed[i] = INFT(NFT_GOC).getClaimStatus(_tickets[i]);
            _reward[i] = ILottery(Lottery_GOC).getRewardView(_tickets[i]);
        }
    }

    /**
     * @dev Get all NFTs of the user
     * @param _user user address
     * @return _tickets NFT Token ID
     * @return _issueIndex release index
     * @return _claimed Whether to claim the prize
     * @return _reward bonus
     */
    function getUserHUSDTickets(address _user)
        public
        view
        returns (
            uint256[] memory _tickets,
            uint256[] memory _issueIndex,
            bool[] memory _claimed,
            uint256[] memory _reward
        )
    {
        _tickets = ILottery(Lottery_HUSD).getUserInfo(_user);
        _issueIndex = new uint256[](_tickets.length);
        _claimed = new bool[](_tickets.length);
        _reward = new uint256[](_tickets.length);
        address NFT_HUSD = ILottery(Lottery_HUSD).lotteryNFT();
        for (uint256 i = 0; i < _tickets.length; i++) {
            _issueIndex[i] = INFT(NFT_HUSD).getLotteryIssueIndex(_tickets[i]);
            _claimed[i] = INFT(NFT_HUSD).getClaimStatus(_tickets[i]);
            _reward[i] = ILottery(Lottery_HUSD).getRewardView(_tickets[i]);
        }
    }

    /**
     * @dev Get all lottery numbers of the user
     * @param _tickets NFT Token ID array
     * @return _numbers lottery number array
     */
    function getGOCLotteryNumbers(uint256[] memory _tickets) public view returns (uint8[4][] memory _numbers) {
        _numbers = new uint8[4][](_tickets.length);
        address NFT_GOC = ILottery(Lottery_GOC).lotteryNFT();
        for (uint256 i = 0; i < _tickets.length; i++) {
            _numbers[i] = INFT(NFT_GOC).getLotteryNumbers(_tickets[i]);
        }
    }

    /**
     * @dev Get all lottery numbers of the user
     * @param _tickets NFT Token ID array
     * @return _numbers lottery number array
     */
    function getHUSDLotteryNumbers(uint256[] memory _tickets) public view returns (uint8[4][] memory _numbers) {
        _numbers = new uint8[4][](_tickets.length);
        address NFT_HUSD = ILottery(Lottery_HUSD).lotteryNFT();
        for (uint256 i = 0; i < _tickets.length; i++) {
            _numbers[i] = INFT(NFT_HUSD).getLotteryNumbers(_tickets[i]);
        }
    }
}