FROM alpine:3.19.1


RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update git iptables bash easy-rsa pamtester libqrencode wget tar build-base libnl3-dev libcap-ng-dev lz4-dev lzo-dev openssl-dev linux-pam-dev && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*


# For OpenVPN 2.6.x use the patches from the 2.6 directory, but take note this is not compatible with DCO so for OpenVPN 2.6.x add to the makefile (feeds/packages/net/openvpn/makefile): --disable-dco
RUN cd /tmp && \
    wget https://swupdate.openvpn.org/community/releases/openvpn-2.6.10.tar.gz && \
    tar xf openvpn-2.6.10.tar.gz && \
    git clone https://github.com/ahhajlou/OpenWRT-OpenVPN-scramble && \
    cd openvpn-2.6.10 && \
    cp /tmp/OpenWRT-OpenVPN-scramble/2.6/* . && \
    bash -c 'for i in `ls 99*`; do git apply $i; done' && \
    ./configure --disable-dco && \
    make && make install


RUN cd /tmp && \
    git clone https://github.com/ahhajlou/docker-openvpn && \
    cp /tmp/docker-openvpn/bin/* /usr/local/bin && \
    chmod a+x /usr/local/bin/*

RUN rm -rf /tmp/*
## delete unnecessary packages to reduce final docker image size
RUN apk del git wget build-base

RUN mkdir /etc/openvpn || echo "/etc/openvpn directory exists."

ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]
