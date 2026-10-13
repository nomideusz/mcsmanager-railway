# Pinned: a silent upstream rebase would hit every deploy of this template at once.
# The daemon image (Ubuntu + Node 20 + Java 21) is the base: game servers run in it.
FROM githubyumao/mcsmanager-daemon:v10.19.0

# The panel is plain JS (no native modules), so it runs on the daemon's Node.
COPY --from=githubyumao/mcsmanager-web:v10.19.0 /opt/mcsmanager/web /opt/mcsmanager/web
# Minecraft 26.x needs Java 25; it also runs 1.21.x. Java 21 stays at /opt/java/openjdk.
COPY --from=eclipse-temurin:25.0.4.1_1-jre-noble /opt/java/openjdk /opt/java/25
ENV JAVA_HOME=/opt/java/25 PATH=/opt/java/25/bin:$PATH
# Railway gives one public port: Caddy serves the panel and, under /daemon, the daemon
# (the browser talks to the daemon directly for the console and files).
COPY --from=caddy:2.11.7 /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh

# Railway gives a service one volume, mounted at /data; panel and daemon state live there.
RUN rm -rf /opt/mcsmanager/web/data /opt/mcsmanager/web/public/upload_files /opt/mcsmanager/daemon/data \
 && ln -s /data/web /opt/mcsmanager/web/data \
 && ln -s /data/uploads /opt/mcsmanager/web/public/upload_files \
 && ln -s /data/daemon /opt/mcsmanager/daemon/data

ENTRYPOINT ["/railway-entrypoint.sh"]
