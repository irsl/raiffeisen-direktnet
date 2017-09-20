# raiffeisen-direktnet
Poor man's transaction history parser for the Raiffeisen Direktnet banking website. Welcome PSD0!

Usage:

```
docker build -t raiffeisen https://github.com/irsl/raiffeisen-direktnet/
docker run -e DIREKTNET_USERNAME=foo -e DIREKTNET_PASSWORD=sdf -e DIREKTNET_REPORT_TRANSACTIONS_SERVICE_URL=https://some.url/callback --restart unless-stopped raiffeisen
```

The log would contain something like this:

```
[Sun Sep 17 16:56:26 2017] Fetching main page
[Sun Sep 17 16:56:27 2017] Got session details
[Sun Sep 17 16:56:27 2017] Logging in...
[Sun Sep 17 16:56:29 2017] Login was successful
[Sun Sep 17 16:56:29 2017] Found account number: ***
[Sun Sep 17 16:56:32 2017] Polling succeeded: 10/10
[Sun Sep 17 16:56:32 2017] Reporting transactions to remote site: https://some.url/callback
[Sun Sep 17 16:56:32 2017] Report succeeded, marking these transactions being succesful
```

If you want the script be persistent (so that transactions are reported only once even when the script is restarted), do cross-mount a volume for it as /tmp having a directory called `raiffeisen` writeable by uid `23101`.

The `DIREKTNET_REPORT_TRANSACTIONS_SERVICE_URL` variable is a URL to a webhook which will receive the application/json payload of the transactions. The payload is a JSON array of hashes. An example:

```
[
{"recipient_extra":"some extra info","date":"2017-09-11","currency":"HUF","amount":"3600.00","comment":["3.600, 00 HUF V\u00e1s\u00e1rl\u00e1s"],"id":"214T170911M1EFD6","category":"Booked items","type":"K\u00e1rtyatranzakci\u00f3","recipient_name":"PayU.HU cinemacity.hu  Budapest"}
]
```

Encoding is as it is coming from the Raiffeisen site, it is not translated. (Meaning you'll most probably receive it in ISO-8859-2).

An example PHP script to consume the callbacks:

```
<?
$postdata = file_get_contents("php://input");
$data = json_decode($postdata);

file_put_contents("log.txt", date("c")." ".json_encode($data)."\n", FILE_APPEND);
?>
```
