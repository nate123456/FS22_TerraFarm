# TerraFarm 

A mining mod for Farming Simulator 22. 

## New mining approach

When a node intersects with the ground, call a LOWER action with extreme speed, strength in a small radius on that position. 

Any time volume is removed, generate material heap on the node position. Bucket will auto pick up if in that mode. 

Any time volume is added, remove from bucket. 

If height lock is in effect, set target height and change to set mode vs. lower mode (add negative height)

##