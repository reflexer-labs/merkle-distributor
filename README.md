# Create a distribution

```
npm i -d

# Create the Merkle root & paths 
npm run generate-merkle-root -- --input input.csv --network <kovan|mainnet> --description 'Short distribution description'

# Verify that the merkle path are correct and match the root
npm run verify-merkle-roots

# Submit a PR and review
git checkout -b new-airdrop
git add scripts/gh-page/*
git commit -m"New airdrop"
gh pr create
```

`input.csv` should be a CSV file with the addresses and amounts to be airdropped, see `scripts/example_input.csv`. The amount is a float with 18 decimal (not a wad).
## Deploy the distributor and send the tokens with geb-console
```
🗿 > tx = geb.contracts.merkleDistributorFactory.deployDistributor("<MERKLE ROOT GENERATED ABOVE>", BigNumber.from("<TOTAL TOKEN AMOUNT GENERATED ABOVE>"))
🗿 > metamask(tx)

🗿 > tx = geb.contracts.merkleDistributorFactory.sendTokensToDistributor(<ID OF THE DISTRIBUTION>)
🗿 > metamask(tx)
```

## Publish the new merkle paths on gh-page
```
npm run publish-distribution 
```
The merkle paths file for the front-end will be located at:

Mainnet: https://reflexer-labs.github.io/merkle-distributor/mainnet.json

Kovan: https://reflexer-labs.github.io/merkle-distributor/kovan.json

