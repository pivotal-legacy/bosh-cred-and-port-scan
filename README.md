# What's this?

This is a set of scripts to scan a BOSH director for open ports and default credentials.


# How do I use it?

Edit `directors.yml` to contain your directors. You can use FQDN or IP addresses.


# How do I interpret the results?

If a director has **both**:

* open ports
* AND default credentials

It's vulnerable. These lines will look something like:

```
team1-name | 52.11.22.33 | agent mbus/mbus-password port: open creds: ✗
```


# What do I do?

You should probably nuke vulnerable BOSH directors and their environments.


# Why are there two scripts?

`scan.rb` has nice output like this:

```
team1-name:
  director-address:
    director admin/admin port: closed creds: ✓
    director hm/hm-password port: closed creds: ✓
    nats port: closed creds: ✓
    agent mbus/mbus-password port: closed creds: ✓
    agent mbus-user/mbus-password port: closed creds: ✓
    postgres port: closed creds: ~
    blobstore director/director-password port: closed creds: ✓
    blobstore agent/agent-password port: closed creds: ✓
```

but it's single-threaded and slow.


`scan-parallel.rb` has output like this:

```
team1-name | director-address | agent mbus-user/mbus-password port: closed creds: ✓
team1-name | director-address | agent mbus/mbus-password port: closed creds: ✓
team1-name | director-address | blobstore agent/agent-password port: closed creds: ✓
team1-name | director-address | blobstore director/director-password port: closed creds: ✓
team1-name | director-address | director admin/admin port: closed creds: ✓
team1-name | director-address | director hm/hm-password port: closed creds: ✓
team1-name | director-address | nats port: closed creds: ✓
team1-name | director-address | postgres port: closed creds: ~
```

and runs many scans in parallel, so it's faster ... but the output will need to be sorted afterwards.
