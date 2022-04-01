pragma solidity ^0.4.18;

contract Voting {
    // 添加候选人事件，发生时进行回调
    event AddedCandidate(uint candidateID);

    //owner作为投票人
    address owner;
    function Voting()public {
        owner=msg.sender;
    }
    /*定义了一个modifier但是没有使用，将在继承的合约中使用函数体将在特殊符号 _ 出现的位置被插入，这里代表的是只有Owner调用这个方法时才会被执行，否则报错*/
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    //候选人的结构体
    struct Candidate {
        bytes32 name;  //候选人姓名
        bytes32 party; //候选人政党
        bool gender;   //候选人性别，1 male 0 female
        bool exist;    //用于确认候选人存在
    }

    //投票者的结构体
    struct Voter {
        bytes32 voterID; //投票者的ID
        uint beVotedID;  //被投候选人的ID
    }

    uint numCandidates; //统计候选人数目
    uint numVoters;     //统计投票人数目

    //哈希表，key为uint，value为结构体
    mapping (uint => Candidate) candidates;
    mapping (uint => Voter) voters;
    
    //添加候选人
    function addCandidate(bytes32 name, bytes32 party, bool gender) onlyOwner public {
        // 确认候选人ID
        uint candidateID = numCandidates++;
        // 加入到结构体
        candidates[candidateID] = Candidate(name,party,gender,true);
        emit AddedCandidate(candidateID);
    }

    //投票
    function vote(bytes32 voterID, uint candidateID) public {
        // 如果存在此候选人
        if (candidates[candidateID].exist == true) {
            // 加入到结构体
            voters[numVoters++] = Voter(voterID,candidateID);
        }
    }

    // 遍历统计票数
    function totalVotes(uint candidateID) view public returns (uint) {
        // 初始化
        uint res = 0;
        for (uint i = 0; i < numVoters; i++) {
            // 统计票数
            if (voters[i].beVotedID == candidateID) {
                res++;
            }
        }
        return res; 
    }

    //返回候选人数量
    function getNumOfCandidates() public view returns(uint) {
        return numCandidates;
    }

    //返回投票人数量
    function getNumOfVoters() public view returns(uint) {
        return numVoters;
    }
    //根据name返回候选人ID
    function getCandidate(bytes32 Name) public view returns (uint) {
        for (uint i = 0; i < numCandidates; i++) {
            if (candidates[i].name == Name) {
                return i;
            }
        }
        return 999;
    }
    //根据ID返回候选人信息
    function getCandidate(uint ID) public view returns (uint, bytes32, bytes32, bool) {
        return (ID,candidates[ID].name,candidates[ID].party,candidates[ID].gender);
    }
    //返回投票人信息
    function getVoter(uint ID) public view returns (uint,bytes32,uint) {
        return (ID, voters[ID].voterID,voters[ID].beVotedID);
    }
}
