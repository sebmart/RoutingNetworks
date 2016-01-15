# To do in NetworkTools
- use a geometry package instead of recoding
- get rid of osm package for now (or use completely)
- add test
- transform into real package
- Make visualize scalable
- better query that just downloads the network information and not everything

How to handle timings and fastest paths ? How to create the expanded graph ?
- Timings: set of timings for each edges
- possibilities to compute/precompute routing
- Routing object
  - contain link to network ?
  - time for each edge ?
  - DistanceRouting => with distance (to have shortest paths, etc...)

  how to name them: shortest paths ? / distance routing ?

- How to handle shortest paths ?
- Extended Network => another kind of network object ?
- Shortest paths
- Fastest paths given timings
