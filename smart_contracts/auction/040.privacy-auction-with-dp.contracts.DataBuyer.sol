pragma experimental ABIEncoderV2;
pragma solidity >0.5.0;
import "./DataBuyerInterface.sol";

contract DataBuyer is DataBuyerInterface {
    address dataBuyer;
    string result;
    string requirements;
    uint constant upper_bound = 1e7;
    uint[] theta_vec;
    uint[] result_index;

    // Constructor code is only run when the contract
    // is created
    constructor() public {
      // store self address
      dataBuyer = msg.sender;
    }

    function get_theta_vec() public view returns(uint[] memory _theta_vec){
      return theta_vec;
    }

    function get_result() public view returns(string memory _result) {
      return result;
    }

    function set_requirements(string memory req) public {
      requirements = req;
    } 

    function get_requirements()  override external returns (string memory req) {
      return requirements;
    }

    function qsort(uint[] memory data) private pure {
       quickSort(data, int(0), int(data.length - 1));
    }
    
    function quickSort(uint[] memory arr, int left, int right) private pure{
        int i = left;
        int j = right;
        if(i>=j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] > pivot) i++;
            while (pivot > arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, left, j);
        if (i < right)
            quickSort(arr, i, right);
    }

   function sqrt(uint x) internal pure returns (uint){
       uint n = x / 2;
       uint lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2; 
       }
       return uint(n);
   }

   function calculate_theta_vec(uint budget, uint[] memory epsilons)private pure returns (uint[] memory) {
 
      qsort(epsilons);

      uint[] memory sum_of_square_vec = new uint[](epsilons.length);
      sum_of_square_vec[epsilons.length - 1] = upper_bound **2;
      for(int i = int(epsilons.length-2); i >=0 ; i--) {
        uint i = uint(i);
        sum_of_square_vec[i] = ((sum_of_square_vec[i+1] * epsilons[i+1]**2 / epsilons[i]**2) + upper_bound**2) ;
      }

      uint[] memory theta_vec = new uint[](epsilons.length);
      
      for(uint i = 0; i< theta_vec.length; i++){
        if((theta_vec.length - i)*upper_bound**2 < budget) {
          // alternative 1: sum of square is constraints
          for(uint j = i; j< theta_vec.length; j++) {
            theta_vec[j] = upper_bound;
          }
          break;
        } else if (sum_of_square_vec[i] > budget) {
          // alternative 2:
          //uint factor = sqrt(budget / (sum_of_square_vec[i]*(epsilons[i]**2)));

          for(uint j = i; j< theta_vec.length; j++){
            // WARNING: be careful about over bounds, or down to zero.
            theta_vec[j] = sqrt(((upper_bound**2) * budget * (epsilons[j]**2)) / (sum_of_square_vec[i]*(epsilons[i]**2)));
          }
          break;
        } else {
          // alternative 3: 0 < \theta < 1 is constraints
          budget -= upper_bound;
          theta_vec[i] = upper_bound;
        }
      }
      return theta_vec;

  }


  // step 5, 6
  // now we have epsilons and budget,
  // we select from them and return the index
  function send_budget_and_epsilons(uint budget, uint[] calldata epsilons, uint[] calldata prices) override external returns (uint[] memory){

      delete result_index;
  // TODO
      theta_vec = calculate_theta_vec(budget, epsilons);
      for(uint i = 0; i< epsilons.length; i++) {
        if ( theta_vec[i] >= prices[i] ) {
          result_index.push(i);
        }
      }
      return result_index;
   }

  function send_result(string calldata _result) override external{
    result = _result;
  }
}


