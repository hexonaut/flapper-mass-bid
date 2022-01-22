all    :; forge build --optimize
clean  :; forge clean
test   :; ./test.sh $(match)
deploy :; dapp --use solc:0.8.11 build --optimize && dapp create FlapperMassBidFactory 0xA950524441892A31ebddF91d3cEEFa04Bf454466 0x9759A6Ac90977b93B58547b4A71c78317f391A28
