// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IOracle} from "../Market.sol";

/**
 * Mock oracle: returns a configurable price in DOLA, implementing
 * Market.sol's IOracle interface (used for Market._oracle).
 */
contract MockOracle is IOracle {
    uint public price = 1e26;

    function setPrice(uint v) external { price = v; }

    function getPrice(address, uint) external view returns (uint) { return price; }
    function viewPrice(address, uint) external view returns (uint) { return price; }
}
