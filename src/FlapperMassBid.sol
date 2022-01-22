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

import {
    VowAbstract,
    FlapAbstract,
    DSTokenAbstract,
    DaiJoinAbstract,
    VatAbstract
} from "dss-interfaces/Interfaces.sol";

contract FlapperMassBid {

    struct AuctionCandidate {
        uint256 index;
        uint256 auction;
        uint256 bid;
    }

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    address public immutable owner;
    VowAbstract public immutable vow;
    FlapAbstract public immutable flap;
    DaiJoinAbstract public immutable daiJoin;
    VatAbstract public immutable vat;
    DSTokenAbstract public immutable mkr;

    constructor(address _owner, address _vow, address _daiJoin) {
        owner = _owner;
        vow = VowAbstract(_vow);
        flap = FlapAbstract(vow.flapper());
        daiJoin = DaiJoinAbstract(_daiJoin);
        vat = VatAbstract(daiJoin.vat());
        mkr = DSTokenAbstract(flap.gem());

        // Setup permissions
        mkr.approve(address(flap), type(uint256).max);
        vat.hope(address(daiJoin));
    }

    function findAuctions(
        uint256 startAuctionIndex,
        uint256 endAuctionIndex,
        uint256 maxAuctionsToBid,
        uint256 mkrBidInWads
    ) external view returns (uint256 numAuctions, bytes memory data) {
        require(endAuctionIndex >= startAuctionIndex, "start-must-be-before-end");
        require(maxAuctionsToBid > 0, "at-least-one-auction");
        require(mkrBidInWads > 0, "need-to-bid-something");
        require(mkr.balanceOf(owner) >= mkrBidInWads * maxAuctionsToBid, "not-enough-mkr-in-your-wallet");
        require(mkr.allowance(owner, address(this)) >= mkrBidInWads * maxAuctionsToBid, "not-enough-mkr-allowance");

        uint256 i;
        uint256 beg = flap.beg();
        AuctionCandidate[] memory candidates = new AuctionCandidate[](maxAuctionsToBid);

        for (i = startAuctionIndex; i <= endAuctionIndex; i++) {
            (uint256 bid,, address guy, uint48 tic, uint48 end) = flap.bids(i);

            if (guy == address(0)) continue;                               // Auction doesn't exist
            if (tic <= block.timestamp && tic != 0) continue;     // Auction finished
            if (end > block.timestamp) continue;                           // Auction end
            if (mkrBidInWads <= bid) continue;                             // Bid not high enough
            if (mkrBidInWads * WAD < beg * bid) continue;                   // Bid increase is not above beg

            if (numAuctions < maxAuctionsToBid) {
                // Always append if not full
                candidates[numAuctions] = AuctionCandidate(numAuctions, i, bid);
                
                numAuctions++;
            } else {
                // Potentially add to candidates if it's smaller amount

                // First find the largest candidate to replace
                AuctionCandidate memory largestBidCandidate;
                for (uint256 o = 0; o < maxAuctionsToBid; o++) {
                    AuctionCandidate memory candidate = candidates[o];
                    if (candidate.bid > largestBidCandidate.bid) {
                        largestBidCandidate = candidate;
                    }
                }

                // Replace it if the current bid is smaller
                if (bid < largestBidCandidate.bid) {
                    candidates[largestBidCandidate.index] = AuctionCandidate(largestBidCandidate.index, i, bid);
                }
            }

            uint256[] memory auctions = new uint256[](numAuctions);
            for (i = 0; i < numAuctions; i++) {
                auctions[i] = candidates[i].auction;
            }

            data = abi.encode(mkrBidInWads, auctions);        // Encode for easier copy+paste
        }
    }

    function execute (bytes calldata data) external {
        require(msg.sender == owner, "only-owner");

        (uint256 bid, uint256[] memory auctions) = abi.decode(data, (uint256, uint256[]));
        uint256 lot = vow.bump();

        // At most you will need bid * numAuctions MKR
        mkr.transferFrom(owner, address(this), bid * auctions.length);

        for (uint256 i = 0; i < auctions.length; i++) {
            try flap.tend(auctions[i], lot, bid) {} catch {
                // Carry on if one of the bids fails
            }
        }

        // Transfer any remaining MKR back out
        mkr.transfer(owner, mkr.balanceOf(address(this)));
    }

    function extractDAI(DSTokenAbstract token) external {
        require(msg.sender == owner, "only-owner");

        // Pull DAI out of vat (if any)
        daiJoin.exit(owner, vat.dai(address(this)) / RAY);
    }

}

contract FlapperMassBidFactory {

    address public immutable vow;
    address public immutable daiJoin;

    constructor(address _vow, address _daiJoin) {
        vow = _vow;
        daiJoin = _daiJoin;
    }

    function create() external returns (FlapperMassBid) {
        return new FlapperMassBid(msg.sender, vow, daiJoin);
    }

}
