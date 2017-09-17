# raiffeisen-direktnet
Poor man's transaction history parser for the Raiffeisen Direktnet banking website. Welcome PSD0!

Usage:

```
docker build -t raiffeisen https://github.com/irsl/raiffeisen-direktnet/
docker --rm raiffeisen
```

Where `DIREKTNET_REPORT_TRANSACTIONS_SERVICE_URL` is a URL to a webhook which will receive the application/json payload of the transactions. The payload is a JSON array of hashes. An example:

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
