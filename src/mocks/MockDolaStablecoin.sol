// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "../interfaces/IERC20.sol";

/**
 * Mock DOLA stablecoin (0x865377367054516e17014CcdED1e7d814EDC9ce4).
 * The market's repay() does dola.transferFrom(module, market, amount).
 * This token denies any transferFrom from an address that has no allowance —
 * which the misconfigured module lacks (it only approved sDOLA earlier).
 */
contract MockDolaStablecoin is IERC20 {
    mapping(address => uint) internal _balances;
    mapping(address => mapping(address => uint)) internal _allowances;

    function setBalance(address who, uint v) external { _balances[who] = v; }

    function totalSupply() external view returns (uint) { return 0; }

    function balanceOf(address addr) external view returns (uint) {
        return _balances[addr];
    }

    function transfer(address to, uint amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "insufficient");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "NO_DOLA_BALANCE_OR_APPROVAL");
        require(_balances[from] >= amount, "insufficient balance");
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }
}
