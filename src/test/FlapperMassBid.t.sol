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
pragma solidity 0.8.11;

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
        mkr.approve(address(bidder), type(uint256).max);

        // Fire off a bunch of flap auctions with "zero bids"
        address(flap).setWard(address(this), 1);
        mcd.vat().setWard(address(this), 1);
        mkr.setBalance(address(this), 50_000 ether);
        mcd.vat().hope(address(flap));
        mkr.approve(address(flap), type(uint256).max);

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

    function test_bid_5() public {
        (uint256 numAuctions, bytes memory data) = bidder.findAuctions(firstAuctionIndex, firstAuctionIndex + 4, 5, 15 ether);
        assertEq(numAuctions, 5);

        // Should bid the first five auctions to 15 MKR
        uint256 prevBalance = mkr.balanceOf(address(this));
        bidder.execute(data);
        assertEq(mkr.balanceOf(address(this)), prevBalance + 5 - 5 * 15 * WAD);
        for (uint256 i = 0; i < numAuctions; i++) {
            (uint256 bid,,,,) = flap.bids(firstAuctionIndex + i);
            assertEq(bid, 15 ether);
        }
    }

    function test_gas_search_300_for_150() public {
        uint256 startGas = gasleft();
        bidder.findAuctions(firstAuctionIndex, firstAuctionIndex + 300 - 1, 150, 15 ether);
        emit log_named_uint("gas", startGas - gasleft());
    }

    function test_gas_bid_150() public {
        uint256[] memory auctions = new uint256[](150);
        for (uint256 i = 0; i < 150; i++) {
            auctions[i] = firstAuctionIndex + i;
        }
        bytes memory data = abi.encode(15 ether, auctions);

        uint256 startGas = gasleft();
        bidder.execute(data);
        emit log_named_uint("gas", startGas - gasleft());
    }

    function test_bid_deal_5() public {
        (uint256 numAuctions, bytes memory data) = bidder.findAuctions(firstAuctionIndex, firstAuctionIndex + 4, 5, 15 ether);
        assertEq(numAuctions, 5);

        // Should bid the first five auctions to 15 MKR
        uint256 prevBalance = mkr.balanceOf(address(this));
        bidder.execute(data);
        assertEq(mkr.balanceOf(address(this)), prevBalance + 5 - 5 * 15 * WAD);
        for (uint256 i = 0; i < numAuctions; i++) {
            (uint256 bid,,,,) = flap.bids(firstAuctionIndex + i);
            assertEq(bid, 15 ether);
        }

        GodMode.vm().warp(block.timestamp + flap.ttl() + 1);

        // Deal the auctions
        for (uint256 i = 0; i < numAuctions; i++) {
            flap.deal(firstAuctionIndex + i);
        }

        assertEq(mcd.vat().dai(address(bidder)), 5 * mcd.vow().bump());

        bidder.extractVatDAI();

        assertEq(mcd.dai().balanceOf(address(this)), 5 * mcd.vow().bump() / RAY);
    }

}
