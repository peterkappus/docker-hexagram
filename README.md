# Hexagram in docker

Remember the old Abstraktor generators? Here's the best one pulled out into a single file which can be run stand-alone in a docker container... see below.

`docker build -t hexagram . `

Add your source images to the folder.

`docker run -it hexagram bash`

Inside the container run:

```
ruby hexagram.rb -h #to see options
```

For example... `ruby hexagram.rb  -l 20 -u bruce.out.jpg -s hexagon -m 0.1 -p honeycomb -c 40 bruce.png`
