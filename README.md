# Flapper Mass Bid

Tool to mass bid on flapper auctions. Useful to defend against mass "zero bid" attacks.

Factory = [0x5FC22AA87851C800387E6c2B776613a962F6BCa9](https://etherscan.io/address/0x5FC22AA87851C800387E6c2B776613a962F6BCa9#code)

## Setup

1. Visit https://etherscan.io/address/0x5FC22AA87851C800387E6c2B776613a962F6BCa9#writeContract and connect your wallet you want to bid auctions out of.
2. Call the "create" write function.
3. Find the newly created contract in the transaction you just sent.
4. Verify the newly created contract by just pasting the code from the Factory along with the calldata encoded constructor args. Optimizations are on and Solidity 0.8.11.
5. Give MKR approval to the newly created contract. You can do unlimited or just some safer lower number if you like.

## Bidding auctions

1. Open your contract in Etherscan and go to the write tab.
2. Call `findAuctions(...)` to scan over a range of auctions to return a subset of auctions you can bid on ordered by smallest bid. Testing reveals you can scan around 300 auctions at once for 150 to bid on. Reduce the numbers if you see weird failures.
3. See if the `numAuctions` is bigger than 0. If so paste the `data` binary data into the `execute()` function. It will take care of bid on all the auctions at once.
4. Repeat as much as you want.

## Retrieve DAI/MKR

Use the `extractXXXX()` functions to pull out any MKR or DAI that is sent to the contract.
