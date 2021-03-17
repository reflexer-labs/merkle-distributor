Simple server to serve merkle paths for the Merkle distributor.

This is a Cloudflare worker manually deployed using https://dash.cloudflare.com/.

To deploy:
1. Go to https://dash.cloudflare.com/
2. Create a KV namespace called MERKLE_DISTRIBUTOR
3. Create a worker paste the code in `worker.js` & deploy
4. Go to the settings of the worker and add the KV binding of MERKLE_DISTRIBUTOR under the variable MERKLE_DISTRIBUTOR  