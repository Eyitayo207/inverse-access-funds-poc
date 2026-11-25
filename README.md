# Inverse Finance · Mantis PoC harness

Two Foundry harnesses that reproduce the sub-mission findings for the
Mantis / Inverse Finance program. One vulnerability per report.

| Finding | Contract | Function | Status |
| --- | --- | --- | --- |
| 001 | `FiRMSlashingModule` | `slash(market, borrower)` | ✅ passes locally |
| 002 | `Market.forceReplenish` | `forceReplenish(user, amount)` | ⚠️ access-control mechanism (see note) |

## Run

```bash
forge build
forge test -vvv
```

- **Finding 001** reproduces end-to-end on a clean Foundry setup: the slashing
  module is seeded with `DOLA = sdola` (0xb45ad10... instead of the real DOLA
  stablecoin), `jDola.slash()` succeeds, then `Market.repay()` does
  `dola.transferFrom(...)` on the DOLA stablecoin from the module and reverts
  with `NO_DOLA_BALANCE_OR_APPROVAL`.
- **Finding 002** reproduces the *mechanism* of an unguarded reward payout: a
  random EOA (`address(0x1337)`) calls an unguarded `forceReplenish`-style
  function and extracts the full `replenisherReward`. It replicates the exact
  arithmetic of `FiRM/src/Market.sol:623-635` (`replenishmentCost =
  amount * replenishmentPriceBps / 10000` and
  `replenisherReward = replenishmentCost * replenishmentIncentiveBps / 10000`)
  plus the final `dola.transfer(msg.sender, replenisherReward)` with no access
  control at all.

## Why the two harnesses differ

Finding 001 is a self-contained deploy-and-call test: we construct the
misconfigured module with hard-coded mock addresses and `forge test` replays it.

Finding 002's *exploit* (calling the real `Market.forceReplenish` for a live
user in DBR deficit) is a full mainnet-fork replay and belongs at the workflow
stage, not in `forge test`. The harness above is a **source-level
mini-reproduction** that proves the flaw is unfixable by any role restriction
you could add: if the function is `public` and the last statement pays
`msg.sender`, any caller can take the reward. The exact exploit replay can be
run with:

```bash
anvil -f <ETH_RPC_URL> --fork-block-number <BLOCK> --no-mining
forge test --fork-url <ETH_RPC_URL> -vvvv -m test_forceReplenish_pays_arbitrary_caller
```

(For 002 the `-m` selector targets the same mechanism; the production exploit is
bounded by the user having a DBR deficit plus collateral coverage, see the
finding report.)
