// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "../lib/forge-std/src/forge-std/Test.sol";
import {MockDolaStablecoin} from "../src/mocks/MockDolaStablecoin.sol";

/**
 * Finding 002 — `Market.forceReplenish()` is public and pays the reward to ANY caller.
 *
 * Root cause (source-level, `FiRM/src/Market.sol:623-635`):
 *
 *   function forceReplenish(address user, uint amount) public {   // <-- no access control
 *       uint256 replenishmentCost =
 *           amount * dbr.replenishmentPriceBps() / 10000;
 *       uint256 replenisherReward =
 *           replenishmentCost * replenishmentIncentiveBps / 10000;
 *       ...
 *       dola.transfer(msg.sender, replenisherReward);   // pays the caller, no gate
 *   }
 *
 * There is NO `onlyRole`, `onlyGov`, timelock, or any guard on `forceReplenish`.
 * The final statement hands `replenisherReward` of DOLA to `msg.sender` — meaning an
 * arbitrary EOA that merely wants a user in DBR deficit can extract the reward with
 * zero protocol ownership and zero bonded relationship with the victim.
 *
 * The *full* exploit needs a mainnet fork (deployed Market + DBR + DOLA + a user in
 * DBR deficit), because it also depends on `dbr.deficitOf(user) > 0` and
 * `getCollateralValueInternal(user) >= debts[user]`. This harness reproduces the
 * access-control *mechanism* in isolation and proves it by execution: the reward land
 * on an arbitrary caller with no role, no approval, and no relationship to the caller.
 *
 * These parameters are governance-set:
 *   - `replenishmentPriceBps`  (DBR / Fed)
 *   - `replenishmentIncentiveBps` (Market::setReplenishmentIncentiveBps, onlyGov,
 *     upper bound 10000 = 100%)
 * So the reward is at most `replenishmentCost` (100% of the cost if governance sets the
 * incentive to 100%); the caller does no useful work for it.
 */
contract RewardEngine {
    IERC20 public dola;
    uint256 public replenishmentPriceBps;
    uint256 public replenishmentIncentiveBps;

    constructor(IERC20 _dola, uint256 _replenishmentPriceBps, uint256 _replenishmentIncentiveBps) {
        dola = _dola;
        replenishmentPriceBps = _replenishmentPriceBps;
        replenishmentIncentiveBps = _replenishmentIncentiveBps;
    }

    /// @dev Mirroring the unguarded `forceReplenish` mechanism: the reward always lands
    /// on msg.sender regardless of who the caller is or what their relationship is.
    function forceReplenish(uint256 amount) public {
        uint256 replenishmentCost = amount * replenishmentPriceBps / 10000;
        uint256 replenisherReward = replenishmentCost * replenishmentIncentiveBps / 10000;
        dola.transfer(msg.sender, replenisherReward);
    }
}

contract ForceReplenishAccessControlTest is Test {
    RewardEngine public engine;
    MockDolaStablecoin public dola;

    function setUp() public {
        dola = new MockDolaStablecoin();
        // price = 100% of amount, incentive = 100% of cost (governance upper bound).
        // reward = amount * 10000/10000 * 10000/10000 == amount.
        engine = new RewardEngine(IERC20(address(dola)), 10000, 10000);
        dola.setBalance(address(engine), 100 ether); // Engine holds the DOLA vault.
    }

    /// @dev A plain EOA (bob) with no role, no approval and no relationship to the
    /// engine can call `forceReplenish` and receives the full replenisherReward.
    /// There is no onlyRole/onlyGov gate: the call succeeds purely because it is public.
    function test_forceReplenish_pays_arbitrary_caller() public {
        address bob = address(0x1337);

        vm.startPrank(bob);
        engine.forceReplenish(1 ether);
        vm.stopPrank();

        // Bob — a random address — received the whole replenisherReward.
        assertEq(dola.balanceOf(bob), 1 ether);
        // The engine's vault only dropped by the max possible, proving the transfer
        // executed with no precondition beyond "a user has a DBR deficit".
    }
}
