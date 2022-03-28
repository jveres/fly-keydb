FROM eqalpha/keydb:alpine

RUN apk -U add bash bind-tools

COPY utils/hivemind /usr/bin/
COPY utils/start_keydb.sh /usr/bin/
COPY utils/detect_peers.sh /usr/bin/
COPY etc /etc/

CMD ["/usr/bin/hivemind", "/etc/Procfile"]