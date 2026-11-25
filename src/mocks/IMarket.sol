// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * Mock market (IMarket). Exposes debts(), getCollateralValue() and repay(),
 * matching the FiRMSlashingModule's local IMarket interface used in slash().
 */
interface IMarket {
    function debts(address borrower) external view returns (uint);
    function getCollateralValue(address borrower) external view returns (uint);
    function repay(address borrower, uint amount) external;
}
