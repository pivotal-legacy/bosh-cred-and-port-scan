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

