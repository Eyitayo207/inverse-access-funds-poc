// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {MockJDola} from "../src/mocks/MockJDola.sol";
import {MockDBR} from "../src/mocks/MockDBR.sol";
import {MockSDola} from "../src/mocks/MockSDola.sol";
import {MockDolaStablecoin} from "../src/mocks/MockDolaStablecoin.sol";
import {MockMarket} from "../src/mocks/MockMarket.sol";

interface IJuniorPool {
    function slash(uint amount) external returns (uint slashed);
}
interface IDBR {
    function markets(address) external view returns (bool);
}
interface IERC20 {
    function approve(address pender, uint amount) external;
}
interface IMarket {
    function debts(address borrower) external view returns (uint);
    function repay(address borrower, uint amount) external;
}

/**
 * Minimal treasury proxy so that the Market's escrowImplementation is a
 * self-contained contract in a local fork.
 */
contract MinimalTreasury {
    IERC20 public token;
    address public beneficiary;

    function initialize(IERC20 _token, address _beneficiary) external {
        token = _token;
        beneficiary = _beneficiary;
    }
}

/**
 * FiRMSlashingModule (copy of the real one in JuniorDola/src). The buggy
 * deployment binds its `DOLA` constructor parameter to the sDOLA token
 * (0xb45ad160) instead of the DOLA stablecoin (0x86537736), so the final
 * step of slash() — a transferFrom of the DOLA stablecoin — always reverts.
 */
contract FiRMSlashingModule {
    IJuniorPool public immutable JUNIOR_POOL;
    IDBR public immutable DBR;
    IERC20 public immutable DOLA;
    address public gov;

    constructor(address _slashingPool, address _dbr, address _dola, address _gov) {
        require(_gov != address(0), "Zero address");
        JUNIOR_POOL = IJuniorPool(_slashingPool);
        DBR = IDBR(_dbr);
        DOLA = IERC20(_dola);
        gov = _gov;
    }

    function slash(address market, address borrower) public returns (uint) {
        uint slashed = JUNIOR_POOL.slash(debt(borrower));
        DOLA.approve(market, slashed);
        IMarket(market).repay(borrower, slashed);
        return slashed;
    }

    function debt(address borrower) public view returns (uint) {
        return IMarket(market).debts(borrower);
    }
    address private immutable market;
}

/**
 * Test 1 — FiRMSlashingModule misconfiguration (slash() reverts).
 *
 * The buggy deployment binds `DOLA` -> sDOLA (0xb45ad160) instead of the real
 * DOLA stablecoin (0x86537736). The module only ever approved sdola -> market,
 * but market.repay() does a transferOf the *DOLA stablecoin* from the module,
 * which always reverts. Full confirmation on a mainnet fork.
 */
contract FiRMSlashingModuleMisconfigTest is Test {
    function test_slash_reverts_when_dola_member_backed_by_sdola() public {
        MockSDola sdola = new MockSDola();
        MockDolaStablecoin dola = new MockDolaStablecoin();
        MockDBR dbr = new MockDBR();
        MockJDola jDola = new MockJDola();
        MockMarket market = new MockMarket();

        jDola.setSDOLA(address(sdola));
        market.setDOLA(address(dola));

        // Buggy deployment: module's "DOLA" member = sDOLA.
        FiRMSlashingModule module = new FiRMSlashingModule(address(jDola), address(dbr), address(sdola), address(this));

        vm.warp(block.timestamp + 15 days); // > default activationDelay (14 days)

        // market.repay() transfersFrom the DOLA-stablecoin from the module,
        // which only holds sDOLA -> reverts.
        vm.expectRevert();
        module.slash(address(market), address(0x1));
    }
}
