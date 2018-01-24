# Hexagram in docker

Remember the old Abstraktor generators? Here's the best one pulled out into a single file which can be run stand-alone in a docker container... see below.

`docker build -t hexagram . `

Add your source images to the folder.

`docker run -it -v "$(PWD):/app" hexagram bash`

Inside the container run:

```
ruby hexagram.rb -h #to see options
```

For example... `ruby hexagram.rb  -l 20 -u bruce.out.jpg -s hexagon -m 0.1 -p honeycomb -c 40 bruce.png`

Circular portrait: `ruby hexagram.rb bruce_portrait.png -u square_bruce4.jpg -s circle -p grid -a 5 -l 10 -o 10 -c 1 -m 0.1`
