//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Stakable {
    constructor() {
        stakeholders.push();
    }

    uint256 dailyPercentageYield = 27000; // 0.027% = 1 / 27000

    struct Stake {
        address holder;
        uint256 amount;
        uint256 stakedAt;
    }

    struct Stakeholder {
        address holder;
        Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakeholderIds;    

    event Staked(address indexed holder, uint256 amount, uint256 stakeholderId, uint256 stakedAt);

    function _addStakeholder(address holder) internal returns (uint256) {
        stakeholders.push();
        uint256 id = stakeholders.length - 1;
        stakeholders[id].holder = holder; 
        stakeholderIds[holder] = id;
        return id;
    }

    function _stake(uint256 amount) internal {
        require(amount > 0, "Stakable: you can only stake a positive non null amount");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakedAt = block.timestamp;
        
        if (stakeholderId == 0) {
            stakeholderId = _addStakeholder(msg.sender);
        }

        stakeholders[stakeholderId].stakes.push(Stake(msg.sender, amount, stakedAt));
        emit Staked(msg.sender, amount, stakeholderId, stakedAt);
    }

    function _calculateReward(Stake memory stake) internal view returns (uint256) {
        return ((((block.timestamp - stake.stakedAt) / 1 days) * stake.amount) / dailyPercentageYield);
    }

    function _retrieveReward(uint256 stakeholderId, uint256 stakesCount) internal view returns (uint256, uint256) {
        uint256 totalReward = 0;
        uint256 totalStaked = 0;

        for (uint256 stakeId = 0; stakeId < stakesCount; stakeId++) {
            Stake memory stake = stakeholders[stakeholderId].stakes[stakeId];
            uint256 reward = _calculateReward(stake);
            totalStaked = totalStaked + stake.amount;
            totalReward = totalReward + reward;
        }

        return (totalReward, totalStaked);
    }

    function _emptyHolderStakes(uint256 stakeholderId, uint256 stakesCount) internal {
        for (uint256 stakeId = 0; stakeId < stakesCount; stakeId++) {
            delete stakeholders[stakeholderId].stakes[stakeId];
        }
    }

    function _claimReward() internal returns (uint256) {
        require(stakeholderIds[msg.sender] != 0, "Stakable: address has nothing staked");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakesCount = stakeholders[stakeholderId].stakes.length;
        uint256 totalReward;
        uint256 totalStaked;
        
        (totalReward, totalStaked) = _retrieveReward(stakeholderId, stakesCount);
        _emptyHolderStakes(stakeholderId, stakesCount);
        stakeholders[stakeholderId].stakes.push(Stake(msg.sender, totalStaked, block.timestamp));

        return totalReward;
    }

    function _unstake(uint256 amount) internal returns (uint256) {
        require(stakeholderIds[msg.sender] != 0, "Stakable: address has nothing staked");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakesCount = stakeholders[stakeholderId].stakes.length;
        uint256 totalReward;
        uint256 totalStaked;
        uint256 totalUnstaked;
        
        (totalReward, totalStaked) = _retrieveReward(stakeholderId, stakesCount);

        if (amount > totalStaked) {
            _emptyHolderStakes(stakeholderId, stakesCount);
            stakeholders[stakeholderId].stakes.push(Stake(msg.sender, 0, block.timestamp));
            totalUnstaked = totalReward + totalStaked;
        } else {
            uint256 remainingStake = totalStaked - amount;
            _emptyHolderStakes(stakeholderId, stakesCount);
            stakeholders[stakeholderId].stakes.push(Stake(msg.sender, remainingStake, block.timestamp));            
            totalUnstaked = totalReward + amount;
        }

        return totalUnstaked;
    }

    function stakeReport() external view returns (uint256, uint256) {
        require(stakeholderIds[msg.sender] != 0, "Stakable: address has nothing staked");
        uint256 stakeholderId = stakeholderIds[msg.sender];
        uint256 stakesCount = stakeholders[stakeholderId].stakes.length;
        uint256 totalReward;
        uint256 totalStaked;
        
        (totalReward, totalStaked) = _retrieveReward(stakeholderId, stakesCount);

        return (totalReward, totalStaked);
    }
}