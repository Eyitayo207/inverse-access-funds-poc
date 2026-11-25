// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IMarket} from "./IMarket.sol";
import {MockDolaStablecoin} from "./MockDolaStablecoin.sol";

/**
 * Mock market (IMarket impl).
 * repay() does dola.transferFrom(payer=the module, market, amount).
 * The MockDolaStablecoin denies transferFrom unless the payer has allowance /
 * balance on the DOLA stablecoin — which the misconfigured module lacks.
 */
contract MockMarket is IMarket {
    MockDolaStablecoin public dola;

    mapping(address => uint) public override debts;

    function setDOLA(address _dola) external { dola = MockDolaStablecoin(_dola); }

    function repay(address, uint amount) override external {
        dola.transferFrom(msg.sender, address(this), amount);
    }

    function getCollateralValue(address) override external view returns (uint) { return 0; }
}
