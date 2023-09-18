// SPDX-License-Identifier: MIT

// This is the entire nft contract, where all the rewards are distributed. 

pragma solidity ^0.8.17;

import "./stakingSetup.sol";
import "./reentrancyGuard.sol";

contract ERC721 is stakingSetup, ERC165, IERC721, IERC721Metadata, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

    uint256 constant MAX_UINT = (2**256)-1;
    uint64 constant MAX_UINT64 = (2**64)-1;

    string private _name;
    string private _symbol;
    address private AX;
    address private sAX;
    uint64 contractBeginningTimestamp;

    uint96 stakeNonce = 1; // 309,485,009,821,345,068,724,781,055 MAX
    uint128 actionNonce = 1; // Starting, can't be 0, otherwise underflow. 
    uint128 public minStakingAmount;

    struct StakeInfo { // 2 slots
        uint128 amount;
        uint16 stakeMultiplier;
        uint64 startingTime;
        uint64 expiryTime; // Time won't go beyond 8 bytes, max value beyond 10,000 years.
        uint64 rewardsRedeemedTill; // Important variable, determines till when user has claimed. Beginning of a distribution in the beginning of a stake. 
        uint128 actionIdRedeemedTill; // Current action id in the beginning of a stake. 
    }

    struct StakeActionInfo { // About 2 slots (fits in 64 bytes). Can be either a stakeAddition, stakeRedemption or distribution. 
        uint96 stakeId; // 0 stakeId means distribution. 
        uint128 totalStake;
        uint160 totalAdjustedStakeWithMultiplier;
        uint64 timestamp;
        bool isStakeAddition; // False could mean distribution or redemption both.
    }

    uint256 public temporary;
    uint256 public temporary2;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => StakeInfo) public stakeDetails; // tokenId -> stakeinfo
    mapping(uint128 => StakeActionInfo) public actionInfo; // actionId -> stakeActionInfo

    mapping(uint64 => uint128) public distributions; // timestamp -> distributionAmount
    uint64[] public distributionTimestamps;

    // Work on the events after doing the functions. 

    event StakeMint(address indexed owner, uint128 indexed stakeId, uint128 amount, uint64 expiryTime, STAKE_DURATION duration, uint16 stakeMultiplier);
    event StakeRedemption(address indexed owner, uint256 indexed tokenId, uint128 stakedAmount, uint128 redeemedAmount); // redeemedAmount is lower when we impose a penalty.
    event FixedRewardDistribution(uint64 indexed timestamp, uint128 amount);
    event RewardRedemption(address indexed owner, uint256 indexed tokenId, uint256 rewardsRedeemedTill, uint256 accumulatedReward);


    constructor(address _AX, address _sAX, uint128 _minStakingAmount) {
        _name = "Fixed Staking AX";
        _symbol = "fAX";
        
        AX = _AX;
        sAX = _sAX;
        minStakingAmount = _minStakingAmount;
    }

    modifier basicTestingChecks() {
        // Checking if stake or action nonces by any chance get duplicated. 
        // Checks, adding them anyway, to see if they ever pop out while testing. 
        require(stakeDetails[stakeNonce].startingTime == 0, "stake: Stake nonce already exists");
        require(actionInfo[actionNonce].timestamp == 0, "stake: Action nonce already exists");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        delete _tokenApprovals[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // My functions after here

    function stake(uint128 amount, STAKE_DURATION duration) public basicTestingChecks() nonReentrant() { // Finished and tested at least once. 
        // Basic checks
        require(_msgSender() != address(0), "stake: Address can't be 0 address.");
        require(amount >= minStakingAmount, "stake: Can't stake less than minimum staking amount");
        require(IERC20(AX).balanceOf(_msgSender()) >= amount, "stake: Insufficient balance");
        require(IERC20(AX).allowance(_msgSender(), address(this)) >= amount, "stake: Transfer not approved");
        
        // See if there's anything I can add. 
        if(stakeNonce == 1) contractBeginningTimestamp = uint64(block.timestamp); // Setting the timestamp for when the contract starts. 

        stakeDetails[stakeNonce] = StakeInfo(amount, stakingMultiplier[duration], uint64(block.timestamp), uint64(block.timestamp) + secondsInStakeDuration[duration], getRewardsRedeemedTill(uint64(block.timestamp)), actionNonce);
        actionInfo[actionNonce] = StakeActionInfo(stakeNonce, getTotalStake() + amount, getTotalAdjustedStake() + ((amount * stakeDetails[stakeNonce].stakeMultiplier) / 100), uint64(block.timestamp), true);

        _safeMint(_msgSender(), stakeNonce);

        stakeNonce += 1;
        actionNonce += 1;
        TransferHelper.safeTransferFrom(AX, _msgSender(), address(this), amount);

        // Emit event
        emit StakeMint(_msgSender(), stakeNonce - 1, amount, uint64(block.timestamp) + secondsInStakeDuration[duration], duration, stakingMultiplier[duration]);
    }

    function redeemRewards(uint96 tokenId) public basicTestingChecks() nonReentrant() { // Finished on my end, just test. 
        // Place more checks if necessary

        require(_msgSender() != address(0), "redeemRewards: Address can't be 0 address.");
        require(ownerOf(tokenId) == _msgSender(), "redeemRewards: Owner is not caller or token owner.");
    
        uint64 lastDistribution = uint64(distributionTimestamps.length - 1); // Becomes negative if no distribution happened. 

        // Doesn't _redeemRewards in case they're already redeemed till last. 
        require(distributionTimestamps[lastDistribution] > stakeDetails[tokenId].rewardsRedeemedTill, "redeemRewards: All rewards already redeemed till now.");
        _redeemRewards(_msgSender(), tokenId, block.timestamp);
    }

    function redeemStake(uint96 tokenId, bool redeemWithPenalty) public basicTestingChecks() nonReentrant() { // Finished and tested once. 
        // Place full checks to ensure the NFT. 
        uint64 expiry = stakeDetails[tokenId].expiryTime;
        uint128 stakeAmount = stakeDetails[tokenId].amount;
        uint16 stakeMultiplier = stakeDetails[tokenId].stakeMultiplier;
        uint128 amountRedeemed = stakeAmount;

        require(expiry != 0, "redeemStake: Invalid NFT");
        require(_msgSender() != address(0), "redeemStake: Address can't be 0 address.");
        require(ownerOf(tokenId) == _msgSender(), "redeemStake: Owner is not caller or token owner.");

        uint64 lastDistribution = uint64(distributionTimestamps.length - 1);

        if(distributionTimestamps[lastDistribution] > stakeDetails[tokenId].rewardsRedeemedTill) { // Just a check to avoid running _redeemRewards and costing gas. 
            _redeemRewards(_msgSender(), tokenId, block.timestamp); // Redeeming all rewards till now first. 
        }

        if(block.timestamp < expiry) { // Normal redemption current time crosses expiry, amountRedeemed == stakedAmount. 
            uint64 totalStakeTime = expiry - stakeDetails[tokenId].startingTime;
            uint64 stakeElapsedTillNow = uint64(block.timestamp) - stakeDetails[tokenId].startingTime;
            uint64 stakeCompletionPercent = uint64(stakeElapsedTillNow * 100) / totalStakeTime;

            require(redeemWithPenalty == true, "redeemStake: Can't redeem this stake without a penalty.");

            if(stakeCompletionPercent < 50) {
                amountRedeemed = stakeAmount / 4; // 75% penalty
            } else {
                amountRedeemed = stakeAmount / 2; // 50% penalty
            }
        }

        actionInfo[actionNonce] = StakeActionInfo(tokenId, getTotalStake() - stakeAmount, getTotalAdjustedStake() - ((stakeAmount * stakeMultiplier) / 100), uint64(block.timestamp), false);
        delete stakeDetails[tokenId];
        actionNonce += 1;

        TransferHelper.safeTransfer(AX, _msgSender(), amountRedeemed);
        _burn(tokenId);

        emit StakeRedemption(_msgSender(), tokenId, stakeAmount, amountRedeemed);
    }

    function _redeemRewards(address owner, uint256 tokenId, uint256 redeemRewardsTill) internal { // Needs to be gas efficient function af. What if redeemRewardsTill is too big. Is only callable by redeemStake and redeemRewards. 
        // Need to do checks if NFT is even valid to receive rewards. 
        // Don't do anything if he has already claimed rewards till the latest distributions, as redeemStake() might call this function too. 
        
        uint64 redeemRewardsFrom = stakeDetails[tokenId].rewardsRedeemedTill;
        
        // Check if there are any distributions available. 
        require(distributionTimestamps.length != 0, "_redeemRewards: No rewards to redeem.");
        require(redeemRewardsTill <= block.timestamp, "_redeemRewards: Redeem till timestamp can't be more than current time.");
        require(redeemRewardsTill > redeemRewardsFrom, "_redeemRewards: Can't redeem rewards that don't exist.");

        uint128 myAdjustedStake = (stakeDetails[tokenId].stakeMultiplier * stakeDetails[tokenId].amount) / 100; // Works
        uint128 currentActionId = stakeDetails[tokenId].actionIdRedeemedTill + 1; // It will get redefined over and over again inside the for loop.
        uint256 accumulatedReward;

        // Have to ensure that the for and while loops run only a certain number of times. And not unlimited times, maybe that could cause accumulatedRewards to be massive?

        for(uint256 i = 0; i < distributionTimestamps.length; i++) { // what if a distributionTime == stakeTime, then no reward. 
            if(distributionTimestamps[i] > redeemRewardsTill) break; // Either runs out of distributions, as in the previous statement. Or breaks the loop. Works. 

            if(distributionTimestamps[i] > redeemRewardsFrom) {
                require(distributionTimestamps[i] >= stakeDetails[tokenId].startingTime, "_redeemRewards: Distribution timestamp isn't supposed to be before the starting of the stake.");

                uint128 currentTotalReward = distributions[distributionTimestamps[i]];
                uint64 currentTotalDistributionTime = distributionTimestamps[i] - redeemRewardsFrom;
                
                while(actionInfo[currentActionId].timestamp <= distributionTimestamps[i]) { // Action timestamp can very well be equal to the distribution action. Now can this be misused? Because upar wali ip statement mein hi invalidate ho jayega. 
                    // Making sure that currentActionId is a valid action. 
                    require(actionInfo[currentActionId].timestamp > 0, "_redeemRewards: Invalid actionId.");

                    uint128 previousActionId = currentActionId - 1;
                    uint160 currentTotalAdjustedStake = actionInfo[previousActionId].totalAdjustedStakeWithMultiplier;
                    uint64 currentDistributionTime = actionInfo[currentActionId].timestamp - actionInfo[previousActionId].timestamp;

                    uint256 currentLoopReward = (currentDistributionTime * myAdjustedStake * currentTotalReward) / (currentTotalDistributionTime * currentTotalAdjustedStake);
                    accumulatedReward += currentLoopReward;

                    currentActionId += 1;

                    if(actionInfo[currentActionId - 1].timestamp == distributionTimestamps[i]) break; // Break it last mein after compensation. Minus 1 because +1 is aage ka. 
                }
                
                // Updated redeemRewardsFrom after the loop. 
                redeemRewardsFrom = distributionTimestamps[i];
            }
        }

        // When everything goes well and good, update till when user redeemed rewards along with actionId. 
        // And because this is an action also, a stake action will be updated last mein. I don't think it is. Agar koi banda redeem kar rha hai toh mujhe kya? Recheck this statement. 
        
        stakeDetails[tokenId].rewardsRedeemedTill = redeemRewardsFrom;
        stakeDetails[tokenId].actionIdRedeemedTill = currentActionId - 1;
        TransferHelper.safeTransfer(AX, owner, accumulatedReward);

        // Emit event here
        emit RewardRedemption(owner, tokenId, redeemRewardsFrom, accumulatedReward);
    }

    function _distributeReward(uint128 amount) internal { // Works perfectly till now.
        // Recording the distribution and sets up action id. 

        // ChatGPT mentioned to make sure that distributions and distribution timestamps are the same length, figure out of it's true or not. 
        uint64 timestamp = uint64(block.timestamp);

        distributions[timestamp] = amount;
        distributionTimestamps.push(timestamp);

        actionInfo[actionNonce] = StakeActionInfo(0, actionInfo[actionNonce - 1].totalStake, actionInfo[actionNonce - 1].totalAdjustedStakeWithMultiplier, uint64(block.timestamp), false);
        actionNonce += 1;

        TransferHelper.safeTransferFrom(AX, _msgSender(), address(this), amount);

        emit FixedRewardDistribution(timestamp, amount);
    }

    function distributeReward(uint128 amount) public onlyOwner() nonReentrant() {
        // Split the distribution between flexbile and fixed. Of course, only after finishing the fungible token contract. 

        _distributeReward(amount);
    }

    function changeMinimumStakingAmount(uint128 _newMinStake) public onlyOwner() {
        minStakingAmount = _newMinStake;
    } 

    function getStakeInfo(uint256 tokenId) public view returns(StakeInfo memory) {
        return stakeDetails[tokenId];
    }

    function getTotalStake() public view returns(uint128) {
        return actionInfo[actionNonce - 1].totalStake;
    }

    function getTotalAdjustedStake() internal view returns(uint160) {
        return actionInfo[actionNonce - 1].totalAdjustedStakeWithMultiplier;
    }

    // function _getStartingDistributionKey() public view returns() { // On halt, maybe not even needed cuz 26 distributions per year. 
    //     for(uint256 i = 0; i < distributionTimestamps.length; i++) {

    //     }
    // }

    function getRewardsRedeemedTill(uint64 stakingTimestamp) internal view returns(uint64) {
        uint64 redeemedTill;

        for(uint256 i = 0; i < distributionTimestamps.length; i++) {
            if(stakingTimestamp >= distributionTimestamps[i] && stakingTimestamp < distributionTimestamps[i+1]) {
                redeemedTill = distributionTimestamps[i];
                break;
            }
        }

        if(redeemedTill == 0) redeemedTill = contractBeginningTimestamp;
        return redeemedTill;
    }

    function destruct() public {
        SELFDESTRUCT
    }

    // Maybe a function to calculate how much reward dude's currently supposed to get?

    // A function to also disable further staking, in case I've upgraded to a different contract. 
    // Emergency function to make everyone withdraw everything. 
    // If I do the fAX collateralize thing, then I would need to sell all their AX immediately na. 
}