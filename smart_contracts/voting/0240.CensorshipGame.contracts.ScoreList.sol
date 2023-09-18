// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract ScoreList {
  
  struct ScoreListItem {
    address prev;
    uint256 score;
    address next;
  }

  address constant internal SCORE_LIST_GUARD = address(1);
  uint256 internal scoreListLength;
  address internal scoreListTail = address(1);

  address public cutOffAddress;
  uint256 public cutOffPoint;
  mapping(address => ScoreListItem) public scoreList;


  constructor() {
    scoreList[SCORE_LIST_GUARD] = ScoreListItem(address(0), type(uint256).max, address(0));
  }

  function _append(address player) internal {
    scoreList[scoreListTail].next = player;
    scoreList[player] = ScoreListItem(scoreListTail, 0, address(0));
    scoreListTail = player;
    scoreListLength++;
  }

  function _insert(address player, uint256 score) internal {
    address candidate = SCORE_LIST_GUARD;
    while(true) {
      if(scoreList[player].score >= scoreList[candidate].score) {
        scoreList[player] = ScoreListItem(scoreList[candidate].prev, score, candidate);
        scoreList[scoreList[candidate].prev].next = player;
        scoreList[candidate].prev = player;
        if(scoreList[player].score > scoreList[cutOffAddress].score)
          cutOffAddress = cutOffAddress = scoreList[cutOffAddress].prev;
        if(candidate == scoreListTail)
          scoreListTail = player;
        return;
      }
      candidate = scoreList[candidate].next;
    }
  }

  function _getIndex(uint256 index) internal view returns (address) {
    require(index < scoreListLength, "INDEX TOO LONG");
    address candidate = SCORE_LIST_GUARD;
    for(uint256 i; i < index + 1; i++) {
      candidate = scoreList[candidate].next;
      if (i == index) return candidate;
    }
  }

  function _remove(address player) internal {
    scoreList[scoreList[player].next].prev = scoreList[player].prev;
    scoreList[scoreList[player].prev].next = scoreList[player].next;
    if(player == scoreListTail)
      scoreListTail = scoreList[player].prev;
    if(scoreList[player].score > scoreList[cutOffAddress].score)
      cutOffAddress = scoreList[cutOffAddress].next;
    scoreList[player] = ScoreListItem(address(0), 0, address(0));
  }

  function _updateScoreList(address player, uint256 score) internal {
    _remove(player);
    _insert(player, score);
  }
}