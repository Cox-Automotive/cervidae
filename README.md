# cervidae

Get an ELK stack up and running quickly and easily on a Linux machine. A lot of assumptions are made, but feel free to submit bug reports or feature requests to make it easier for everyone.

## How it works

Download the cervidae.sh script to your Linux box and run it. The only prerequisites are java and a compiler (gcc tested).

```
$ wget -O - https://raw.githubusercontent.com/Cox-Automotive/cervidae/master/cervidae.sh | bash
```

The default Logstash configuration is watching ```/var/logs/httpd/access.log```, and you'll probably want to add to that. Start it up with

```
$ ./bin/elk start
```

## What to expect

A running instance of Elasticsearch, Logstash, and Kibana as well as configuration files and helper scripts.

## Who is this for?

Mainly developers looking to run an ELK stack on their dev box. 

## TODO

* Additional Elasticsearch scripts for pulling reports (in Python)
* Elasticsearch template files
* Logstash config file creator
* Cleanup and testing
