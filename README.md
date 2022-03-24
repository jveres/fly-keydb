# KeyDB on Fly

KeyDB is a multithreaded fork of Redis designed for high performance on multi-core servers.

KeyDB also supports a _multimaster_ mode which is uniquely suited to deployment on Fly. This mode
does not currently enforce strong consistency, but it's useful for a few scenarios today.

## Deployment

Get the [Fly CLI](https://fly.io/blog/last-mile-redis/) and a Fly account.

Then, clone this repo and run `fly launch`. Don't deploy yet - we need to do a bit more setup.

By default, this configuration enables authentication on KeyDB. So let's set a password:

```
fly secrets set KEYDB_PASSWORD=password
```

Now let's add storage volumes in Chicago and Amsterdam for KeyDB persistent storage.

```
fly volumes create keydb_server --region ord
fly volumes create keydb_server --region ams
```

Now we're ready to deploy!

```
fly deploy
```

Finally, we'll want to deploy an application in the same regions and connect to the region-local KeyDB.

That can be done by building the instance hostname using the region and application name. For example,
the Chicago instance is available at `redis://password:password@ord.multimaster-keydb-example.internal`.

## keydb-cli

```
keydb-cli -h $FLY_APP_NAME.internal
```
