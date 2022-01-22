// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Sam MacPherson (hexonaut)
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.8.10;

import "dss-test/DSSTest.sol";
import "dss-interfaces/Interfaces.sol";

import "../FlapperMassBid.sol";

contract FlapperMassBidTest is DSSTest {

    using GodMode for *;

    FlapAbstract flap;
    DSTokenAbstract mkr;
    FlapperMassBidFactory factory;
    FlapperMassBid bidder;

    uint256 firstAuctionIndex;

    function setupEnv() internal virtual override returns (MCD) {
        return autoDetectEnv();
    }

    function postSetup() internal virtual override {
        flap = FlapAbstract(mcd.chainlog().getAddress("MCD_FLAP"));
        mkr = DSTokenAbstract(mcd.chainlog().getAddress("MCD_GOV"));

        factory = new FlapperMassBidFactory(address(mcd.vow()), address(mcd.daiJoin()));
        bidder = factory.create();

        // Fire off a bunch of flap auctions
        address(flap).setWard(address(this), 1);
        mcd.vat().setWard(address(this), 1);
        mkr.setBalance(address(this), 50_000 ether);

        uint256 numAuctions = 300;
        uint256 lot = mcd.vow().bump();
        firstAuctionIndex = flap.kicks() + 1;
        mcd.vat().suck(address(this), address(this), numAuctions * lot);
        for (uint256 i = 0; i < numAuctions; i++) {
            flap.kick(lot, 0);
            flap.tend(flap.kicks(), lot, 1);
        }

        assertEq(flap.kicks(), firstAuctionIndex + numAuctions - 1);
    }

    function test_mass_bid() public {

    }

}
