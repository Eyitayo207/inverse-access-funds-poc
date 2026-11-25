// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * Standard ERC-20 interface (matches the real repo's
 * src/interfaces/IERC20.sol imported by FiRM/src/Market.sol).
 */
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}
