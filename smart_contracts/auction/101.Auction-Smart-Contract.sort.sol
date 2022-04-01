pragma solidity ^0.4.7;

contract Auction {
    uint[] public data;
    function set(uint[] _data) public
    { 
        data = _data; 
    }
    function sort() public
    {
        if (data.length == 0)
            return;
        mergeSort(data, uint(0), uint(data.length - 1));
    }
    function merge(uint[] storage arr, uint l, uint m, uint r) internal
    { 
    uint i;
    uint j;
    uint k;
    uint n1 = m - l + 1; 
    uint n2 =  r - m; 
 
    uint[] memory L = new uint[](n1);
    uint[] memory R = new uint[](n2);
  
    for (i = 0; i < n1; i++) 
        L[i] = arr[l + i]; 
    for (j = 0; j < n2; j++) 
        R[j] = arr[m + 1+ j]; 
  
    
    i = 0; 
    j = 0; 
    k = l; 
    while (i < n1 && j < n2) 
    { 
        if (L[i] <= R[j]) 
        { 
            arr[k] = L[i]; 
            i++; 
        } 
        else
        { 
            arr[k] = R[j]; 
            j++; 
        } 
        k++; 
    } 
  
    while (i < n1) 
    { 
        arr[k] = L[i]; 
        i++; 
        k++; 
    } 
  
    while (j < n2) 
    { 
        arr[k] = R[j]; 
        j++; 
        k++; 
    } 
    } 
    
    function mergeSort(uint[] storage arr, uint l, uint r) internal
    { 
    if (l < r) 
    { 
        uint m = l+(r-l)/2; 
  
        mergeSort(arr, uint(l), uint(m)); 
        mergeSort(arr, uint(m+1), uint(r)); 
  
        merge(arr, uint(l), uint(m), uint(r)); 
    } 
    } 
    function show() public view returns (uint[])
    {
        return data;
    }
    
}
