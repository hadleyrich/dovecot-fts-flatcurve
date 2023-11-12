ARG ALPINE_VERSION=3.18

FROM alpine:$ALPINE_VERSION AS builder

ARG ALPINE_VERSION
ARG DOVECOT_VERSION=2.3.21
ARG PIGEONHOLE_VERSION=0.5.21

RUN apk add --no-cache \
	autoconf \
	automake \
	bash \
	bison \
	flex \
	g++ \
	gcc \
	gettext-dev \
	git \
	icu-dev \
	libexttextcat-dev \
	libstemmer-dev \
	libtool \
	make \
	openssl1.1-compat-dev \
	runuser \
	wget \
	xapian-core-dev

RUN mkdir /dovecot

RUN git clone --depth 1 --branch $DOVECOT_VERSION https://github.com/dovecot/core.git /dovecot/core
RUN cd /dovecot/core && \
	./autogen.sh && \
	PANDOC=false ./configure \
	--prefix=/usr \
	--sysconfdir=/etc \
	--with-icu \
	--with-rundir=/run/dovecot \
	--with-stemmer \
	--with-textcat && \
	make install

RUN git clone --depth 1 https://github.com/slusarz/dovecot-fts-flatcurve.git /dovecot/fts-flatcurve
RUN cd /dovecot/fts-flatcurve && ./autogen.sh && ./configure --prefix=/usr && make install

RUN git clone --depth 1 --branch $PIGEONHOLE_VERSION https://github.com/dovecot/pigeonhole.git /dovecot/pigeonhole
RUN cd /dovecot/pigeonhole && ./autogen.sh && ./configure --prefix=/usr && make install

FROM alpine:$ALPINE_VERSION

RUN apk add --no-cache \
	bash \
	ca-certificates \
	libstemmer \
	libexttextcat \
	icu-libs \
	libxapian \
	openssh-client \
	openssl1.1-compat \
	rspamd-client \
	tini

COPY --from=builder /usr/bin/dove* /usr/bin/
COPY --from=builder /usr/sbin/dove* /usr/sbin/
COPY --from=builder /usr/lib/dovecot /usr/lib/dovecot
COPY --from=builder /usr/share/dovecot /usr/share/dovecot
COPY --from=builder /usr/libexec/dovecot /usr/libexec/dovecot

# vmail needs to come first, as it needs to be the lowest UID in order to
# have correct permissions to access mailbox directory
RUN addgroup vmail && \
	adduser -DH -G vmail vmail && \
	addgroup dovecot && \
	adduser -DH -G dovecot dovecot && \
	addgroup dovenull && \
	adduser -DH -G dovenull dovenull

COPY etc/dovecot.conf etc/users etc/virtual /etc/dovecot/
COPY quota-warning.sh /usr/local/bin/
COPY learn-spam.sieve learn-ham.sieve /usr/lib/dovecot/sieve/
RUN mkdir -p /var/lib/dovecot/db/ && chown vmail /var/lib/dovecot/db/

EXPOSE 24
EXPOSE 110
EXPOSE 143
EXPOSE 485
EXPOSE 587
EXPOSE 990
EXPOSE 993
EXPOSE 4190
EXPOSE 10010
EXPOSE 12340
EXPOSE 12345

VOLUME ["/etc/dovecot", "/srv/mail"]

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/sbin/dovecot", "-F"]
