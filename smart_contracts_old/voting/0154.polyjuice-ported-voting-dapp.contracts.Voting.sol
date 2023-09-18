pragma solidity ^0.4.18;
// Chúng ta phải chỉ ra version của compiler cho code của contract

contract Voting {
  /* trường mapping phía dưới tương đương với một associative array, lưu dữu liệu
  theo cấu trúc (key => value). Theo đó key của mapping được lưu trữ dưới dạng bytes32 
  dùng để lưu tên của ứng cử viên, còn value được lưu trữ dưới dạng unsigned integer dùng 
  để lưu số phiêu của ứng cử viên: votesReceived[key] = value
  */
  
  mapping (bytes32 => uint8) public votesReceived;
  
  /* Solidity chưa cho phép chuyền vào mảng của strings trong constructor. Do đó
  chúng ta sử dụng mảng bytes32 để lưu trữ danh sách ứng cử viên
  */
  
  bytes32[] public candidateList;
  
  /* Đây là constructor được gọi duy nhất một lần khi deploy contract lên blockchain.
  Khi deploy contract, chúng ta chuyền vào danh sách ứng cử viên. Lưu ý từ phiên bản
  solidity ^0.4.22 mọi constructor sẽ được khai báo bằng cú pháp "constructor(arg)"
  */
  function Voting(bytes32[] candidateNames) public {
    candidateList = candidateNames;
  }

  // Đây là hàm trả về tổng lượng vote cho ứng cử viên tương ứng tính tới thời điểm hiện tại.
  function totalVotesFor(bytes32 candidate) view public returns (uint8) {
    require(validCandidate(candidate));
    return votesReceived[candidate];
  }

  // Hàm bỏ phiếu sẽ tăng 1 vào tổng số phiếu của ứng cử viên tương ứng với tham số
  // truyền vào.
  function voteForCandidate(bytes32 candidate) public {
    require(validCandidate(candidate));
    votesReceived[candidate] += 1;
  }
  
  // Hàm kiểm tra tính hiệu lực của ứng cử viên bằng cách search từ danh sách ứng cử viên
  function validCandidate(bytes32 candidate) view public returns (bool) {
      for(uint i = 0; i < candidateList.length; i++) {
          if (candidateList[i] == candidate) {
            return true;
          }
        }
        return false;
      }
  }
