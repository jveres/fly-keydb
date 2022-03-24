FROM eqalpha/keydb:alpine

RUN apk -U add bash bind-tools

ADD fly /fly/
ADD keydb.conf /etc/

CMD ["/fly/hivemind", "/fly/Procfile"]