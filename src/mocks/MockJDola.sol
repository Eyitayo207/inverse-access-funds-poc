// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * Mock jDOLA vault (IJuniorPool).
 * slash() returns the slashed amount (mirrors the real jDola; it withdraws
 * sDOLA but we keep the mock focused on the misconfig).
 */
interface IJuniorPool {
    function slash(uint amount) external returns (uint);
}

import {MockSDola} from "./MockSDola.sol";

contract MockJDola is IJuniorPool {
    MockSDola public sdola;

    function setSDOLA(address _sdola) external { sdola = MockSDola(_sdola); }

    function slash(uint amount) external returns (uint) {
        return amount;
    }
}
