// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)
        external returns (bool success);
    function approve(address _spender, uint256 _value)
        external returns (bool success);
    function allowance(address _owner, address _spender)
        external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value)
        external returns (bool success);
}