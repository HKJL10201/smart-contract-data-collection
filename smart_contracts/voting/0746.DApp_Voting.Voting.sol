pragma solidity ^0.4.11;
// 指定 compiler 的版本

contract Voting {
  
    // bytes32 -> uint8 的一個 map，用來存候選人的票數
    mapping (bytes32 => uint8) public votesReceived;

    // Solidity 不給傳字串的陣列，所以用 bytes32 的陣列來存候選人列表
    bytes32[] public candidateList;

    // 合約的建構子，傳入候選人列表以建立合約
    function Voting(bytes32[] candidateNames) public {
        candidateList = candidateNames;
    }

    // 檢視某個候選人目前所得的票數
    function totalVotesFor(bytes32 candidate) public returns (uint8) {
        assert(validCandidate(candidate) == true);
        return votesReceived[candidate];
    }

    // 幫某個候選人票數 + 1
    function voteForCandidate(bytes32 candidate) public {
        assert(validCandidate(candidate) == true);
        votesReceived[candidate] += 1;
    }

    // 確認傳入的候選人是否真的在列表中
    function validCandidate(bytes32 candidate) private returns (bool) {
        for(uint i = 0; i < candidateList.length; i++) {
            if (candidateList[i] == candidate) {
                return true;
            }
        }
        return false;
    }
}
