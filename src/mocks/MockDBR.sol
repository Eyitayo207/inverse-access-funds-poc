// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IDolaBorrowingRights} from "../Market.sol";

/**
 * Mock DBR: implements BOTH
 *   - the module's local IJuniorPool/IDBR (markets)  [for FiRMSlashingModule],
 *   - the Market's IDolaBorrowingRights interface
 *     (deficitOf, replenishmentPriceBps, onForceReplenish, ...) [for Market].
 */
interface IDBR {
    function markets(address) external view returns (bool);
}

contract MockDBR is IDBR, IDolaBorrowingRights {
    bool public marketsActive = true;
    uint public replenishmentPriceBps = 100000;
    uint public replenishmentIncentiveBps = 100;
    uint256 internal deficitOfInternal;

    function setMarketActive(bool active) external { marketsActive = active; }
    function setReplenishmentPriceBps(uint v) external { replenishmentPriceBps = v; }
    function setReplenishmentIncentiveBps(uint v) external { replenishmentIncentiveBps = v; }
    function setDeficitOf(address, uint v) external { deficitOfInternal = v; }

    function markets(address) external view returns (bool) { return marketsActive; }
    function deficitOf(address) external view returns (uint) { return deficitOfInternal; }
    function onBorrow(address, uint) external {}
    function onRepay(address, uint) external {}
    function onForceReplenish(address, address, uint, uint) external {}
    function balanceOf(address) external view returns (uint) { return 0; }
}
