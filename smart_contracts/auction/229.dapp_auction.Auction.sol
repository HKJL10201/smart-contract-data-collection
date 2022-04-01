pragma solidity ^0.4.13;

contract Auction {
    
    // 참여자 구조체
    struct User {
        // 계정 주소
        address addr;
        // 참여 금액
        uint    value;
        // 참여자 이름
        string  name;
        // 참여자 주소지
        string  destination;
        // 참여자 전화번호
        string  phone;
    }

    address private owner;
    uint    private numUsers;
    // 현재 경매의 최고가
    uint    public  value;
    // 최고가를 제시한 참여자 주소
    address private lastUser;
    // 경매 종료 여부
    bool    public  isEnd;
    // 최종 낙찰된 참여자 정보
    User    private confirmedUser;
    
    // 미술품 및 주최자 정보 링크
    string  public  url;
    // 링크 페이지의 해시 값
    string  public  pagehash;
    
    // 경매 마감 기간(~까지)
    uint    public  deadline;
    // 상한액
    uint    public  raiseLimit;
    
    // 참여자 목록
    mapping (uint => User) private users;
    
    // 소유자 접근 제한자 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // 계약 생성자 (소유자만 접근) _url: 미술품 정보 링크, _pagehash: 링크 페이지의 해시 값, _deadline: 마감기간, _initValue: 초기금액, _raiseLimit: 상한액
    function Auction(string _url, string _pagehash, uint _deadline, uint _initValue, uint _raiseLimit) {
        owner = msg.sender;
        numUsers = 0;
        value = _initValue;
        isEnd = false;
        url = _url;
        pagehash = _pagehash;
        deadline = now + _deadline;
        raiseLimit = _raiseLimit;
    }
    
    // 경매 체크 (소유자만 접근)
    function checkAuction() public onlyOwner payable returns (address addr, uint value, string name, string destination, string phone) {
        require(!isEnd);
        require(now >= deadline);
        require(numUsers > 0);
        
        uint idx = 0;
        
        while (idx <= numUsers) {
            
            // 최고가를 제시한 참여자일 경우
            if (users[idx].addr == lastUser) {
                // 경매 소유자에게 금액 송금
                if(!owner.send(users[idx].value)) {
                    revert();
                }
                // 최종 낙찰자 정보 저장
                confirmedUser = users[idx];
                
            // 아닐 경우
            } else {
                // 각 참여자에게 금액 환불
                if(!users[idx].addr.send(users[idx].value)) {
                    revert();
                }
            }
            
            idx++;
        }
        
        // 경매 종료 여부 true
        isEnd = true;
        
        // 최종 낙찰자 정보 반환
        return (confirmedUser.addr, confirmedUser.value, confirmedUser.name, confirmedUser.destination, confirmedUser.phone);
    }
    
    // 경매에 참여 _name: 참여자 이름, _destination: 참여자 주소지, _phone: 참여자 전화번호
    function join(string _name, string _destination, string _phone) public payable {
        require(!isEnd);
        require(now < deadline);
        require(msg.value == value);
        
        uint idx = 0;
        
        while (idx <= numUsers) {
            // 이미 참여된 경우 revert
            if (users[idx].addr == msg.sender) {
                revert();
            }
            
            idx++;
        }
        
        // 참여자 정보 추가
        User user = users[numUsers++];
        user.addr = msg.sender;
        user.value = msg.value;
        user.name = _name;
        user.destination = _destination;
        user.phone = _phone;
    }
    
    // 경매 금액 추가
    function raise() public payable {
        require(!isEnd);
        require(now < deadline);
        require(msg.value > 0);
        require(msg.value <= raiseLimit);
        
        uint idx = 0;
            
        while (idx <= numUsers) {
            // 참여자 목록에 있을 경우
            if (users[idx].addr == msg.sender) {
                // 참여 금액에 추가 금액 더함
                users[idx].value += msg.value;
                
                // 참여 금액이 경매 최고가 보다 클 경우
                if (users[idx].value > value) {
                    // 참여 금액을 최고가로 대입
                    value = users[idx].value;
                    // 최고가를 제시한 참여자로 대입
                    lastUser = msg.sender;
                }
                
                // 함수 종료
                return ;
            }
            
            idx++;
        }
        
        // while 블록에서 아무런 처리가 없을 경우 revert
        revert();
    }
    
    function kill() public onlyOwner {
        
        selfdestruct(owner);
    }

}