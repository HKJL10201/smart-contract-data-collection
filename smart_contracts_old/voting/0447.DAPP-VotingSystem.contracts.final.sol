pragma solidity >=0.5.0 <0.6.0;
import "./vote.sol";
import "./utility.sol";

contract _final is vote, utility {
    struct result{
        string[] items;
        mapping(string => candidate[]) final_result;
        mapping (string => bool) item_check;
        mapping (string => uint) ballot_num; 
    }
    function initial_result_item(result storage _result,string memory _item) internal {
        _result.items.push(_item);
        _result.item_check[_item] = false;
        _result.ballot_num[_item] = 0;
    }
    function initial_result_cand(result storage _result,string memory _item, string memory _cand) internal {
        _result.final_result[_item].push(candidate(_cand,_item,0));
    }
    function update_result(result storage _result,ballot memory _ballot) internal {
        _result.item_check[_ballot.item] = true;
        for(uint i=0; i<_result.final_result[_ballot.item].length; i++){
            if(string_compare(_result.final_result[_ballot.item][i].name,_ballot.candidate)) {
                _result.final_result[_ballot.item][i].num += 1;
            }
        }
    }
    function candidate_result(result storage _result,string memory _item, string memory _candidate) view internal returns(uint) {
        for(uint i=0; i<_result.final_result[_item].length; i++){
            if(string_compare(_result.final_result[_item][i].name,_candidate)){
                return _result.final_result[_item][i].num;
            }
        }
    }
    function  final_results(result storage _result,string memory _item) view internal returns(uint,string memory) {
        uint max = 0;
        string memory max_cand;
        for(uint i=0; i<_result.final_result[_item].length; i++){
            if(_result.final_result[_item][i].num > max){
                max = _result.final_result[_item][i].num;
                max_cand = _result.final_result[_item][i].name;
            }
        }
        return (max, max_cand);
    }
}