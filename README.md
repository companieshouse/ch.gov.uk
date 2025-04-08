Some Local Tests for `MojoX::Security::Session`
=========

This branch has some info on how to locally test the session ID (which is built by[MojoX::Security::Session](https://github.com/companieshouse/MojoX-Security-Session/blob/f58539273842a00f8a1c9d2ff3e95ba8faaae0ab/lib/MojoX/Security/Session.pm#L193) )

## scenario 1 (multiple calls to _generate_sessionID)

build a dedicated image and spin up a container as per [these info](https://github.com/companieshouse/ch.gov.uk/blob/cb7a325845ac74ad4f69aa6a08837c4cbfeeea45/Dockerfile.Session.local#L19-L23)

## scenario 2 (multiple GET to chs)

```
$ # start a local CHS with an instance of ch.gov.uk
$ # run a stream of GET
$ out='session.ids2.log'; \
iterations=10000; \
grafana_session='78311d2f13abc3613bac52f192e130a0'; \
now=$(date +%s);  \
:> "$out";  \
(  \
    for i in $(seq "${iterations}"); do  \
        printf "request [$i]: " >> "$out";  \
        curl -s -I 'http://chs.local/' \ \
            -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:137.0) Gecko/20100101 Firefox/137.0'  \
            -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'  \
            -H 'Accept-Language: en-GB,en;q=0.5'  \
            -H 'Accept-Encoding: gzip, deflate'  \
            -H 'Referer: http://account.chs.local/'  \
            -H 'Connection: keep-alive'  \
            -H "Cookie: grafana_session=78311d2f13abc3613bac52f192e130a0; grafana_session_expiry=${now};'" \
            -H 'Upgrade-Insecure-Requests: 1'  \
            -H 'Priority: u=0, i'  \
            -H 'Pragma: no-cache'  \
            -H 'Cache-Control: no-cache' | sed -n '/__SID=/p;' >> "$out";  \
    done;  \
) &

# the above takes roughly 5 sec per GET

$ # check if there are duplicates
$ awk -F '__SID=' '{print $2}' "$out" | awk -F ';' '{print $1}' | sort | uniq -d

```
