// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./VotingStore.sol";
import "./DataType.sol";

// VotingStore 0xEff33E9d503d187ffCc329Cb223649888cc301E7
// Vote  0x0DE85db441e8AE0dC1f15e0Cd487d43cD54758fb

contract Vote is DataType {
    VotingStore public store;
    uint256 public EXPIRE_SECONDS;
    address public storeAddress;

    constructor(address _storeAddress) {
        setStoreContract(_storeAddress);
        EXPIRE_SECONDS = 300;
    }

    // store연결
    function setStoreContract(address _storeAddress) public {
        // 주소 빈값 체크
        require(_storeAddress != address(0), 'Not valid address');
        storeAddress = _storeAddress;
        store = VotingStore(_storeAddress);
    }

    function getStoreAddress() public view returns(address) {
        require(storeAddress != address(0), 'Not valid address');
        return storeAddress;
    }

    // 후보자 생성
    function setCandidates(CandidateNoId[] memory _candidateList) public {
        Candidate[] memory data = new Candidate[](_candidateList.length);
        for (uint256 i = 0; i < _candidateList.length; i++) {
            // id값 세팅
            store.setSerialId(store.getSerialId() + 1);
            data[i] = Candidate(store.getSerialId(), _candidateList[i].name, _candidateList[i].description, _candidateList[i].imageName);
        }
        // Store에 저장
        store.setCandidates(data);
    }

    // 전체 후보자 get
    function getCandidates() public view returns(Candidate[] memory) {
        return store.getCandidates();
    }
    // 각 후보자에 투표
    function vote(uint256 _id) public {
        require(validCandidate(_id), 'Not valid candidate.');
        require(isValidVotingTime(msg.sender), 'Already voted. Impossible voting time.');
        store.setVotingMap(_id, store.getCountById(_id) + 1);
        store.setVotingTimeMap(msg.sender, block.timestamp);
    }

    // 후보자 득표수 조회
    function getCountById(uint256 _id)
        public
        view
        returns (uint256)
    {
        require(validCandidate(_id), 'Not valid candidate.');
        return store.getCountById(_id);
    }

    // 전체 후보자 조회
    function getVotingStatusList() public view returns(VotingStatus[] memory) {
        Candidate[] memory candidates = store.getCandidates();
        VotingStatus[] memory votingStatusList = new VotingStatus[](candidates.length);
        for(uint256 i = 0; i < candidates.length; i++) {
            uint256 candidateId = candidates[i].id;
            bytes32 name = candidates[i].name;
            uint256 count = store.getCountById(candidateId);
            votingStatusList[i] = VotingStatus(candidateId, name, count);
        }
        return votingStatusList;
    }

    function isVoted(address _address) public view returns(bool) {
        require(_address != address(0), 'Not valid address');
        uint256 value = store.getVotingTimeMap(_address);
        return value != 0;
    }

    function isValidVotingTime(address _address) public view returns(bool) {
        require(_address != address(0), 'Not valid address');
        uint256 startTime = store.getVotingTimeMap(_address); // not exsist key (첫 투표일 경우) startTime은 0리턴됨
        // uint256 checkIntervalTime = 5 minutes;

        // 투표시각로 부터 경과시간이 _checkSeconds 이상이면 true 리턴
        return startTime == 0 ? true : (block.timestamp - startTime) >= EXPIRE_SECONDS;
    }

    function getRemaingSeconds(address _address) public view returns(uint256) {
        require(_address != address(0), 'Not valid address');
        uint256 startTime = store.getVotingTimeMap(_address);
        require(startTime != 0, 'Voting Not yet');

        // 경과시간 second단위로 return
        uint256 elapsedTime = block.timestamp - startTime;
        uint256 remaingSeconds = EXPIRE_SECONDS - elapsedTime;
        require(remaingSeconds > 0, 'Already you can vote.');
        return remaingSeconds;
    }

    // 입력값 유효성 체크
    function validCandidate(uint256 _id) public view returns (bool) {
        Candidate[] memory candidates = store.getCandidates();
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].id == _id) {
                return true;
            }
        }
        return false;
    }
}
