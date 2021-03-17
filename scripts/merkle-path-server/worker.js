addEventListener('fetch', (event) => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  
  const headers = { 'content-type': 'application/json' }
  
  // Parse *.workers.dev/<network>/<address>
  const route = request.url.split(".workers.dev/")[1].split("/")
  const network = route[0]
  const address = route[1]

  if((network !== "mainnet" && network !== "kovan") || typeof address !== 'string') {
    return new Response(JSON.stringify({error: "Bad request"}), {
      status: 400,
      headers
    })
  }

  const distributions = JSON.parse(await MERKLE_DISTRIBUTOR.get(network))

  // Return an array of matching entries
  const ret = []
  distributions.forEach((d, i) => {
    if(d.recipients[address]) {
      ret.push({distributionIndex: i+1, ...d.recipients[address]})
    }
  });

  return new Response(JSON.stringify(ret), {headers})
}