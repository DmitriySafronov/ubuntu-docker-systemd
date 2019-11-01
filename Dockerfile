FROM ubuntu:latest

MAINTAINER Dmitriy Safronov <zimniy@cyberbrain.pw>
ENV LANG C.UTF-8

# Container
ENV container=docker

########################################################################################

# Customization
RUN set -x \
# Update package indexes, upgrade packages, install systemd and necessary packages then clean unused packages and package cache
    && apt-get update -y \
    && apt-get full-upgrade -y \
    && apt-get install -y systemd systemd-cron --no-install-recommends 
    && apt-get autoremove --purge -y \
    && apt-get clean -y \
    && rm -rfv /var/lib/apt/lists/* \
# Set systemd as init
    && ln -sf /lib/systemd/systemd /sbin/init \
# Setup logging to console 1
	&& mkdir -p /etc/systemd/journald.conf.d \
	&& echo "[Journal]\nStorage=volatile\nRuntimeMaxUse=100M" > /etc/systemd/journald.conf.d/override.conf \
# Create new systemd target and set it as default target
    && echo "[Unit]\nDescription=For running systemd in docker containers\nRequires=cron.target" > /etc/systemd/system/container.target \
    && systemctl set-default container.target \
# Disable unused targets and services
	&& systemctl mask -- \
					cryptsetup.target \
					local-fs.target \
					local-fs-pre.target \
					swap.target \
					time-sync.target \
					timers.target \
					modules-load.service \
	&& ( export OLD_PWD=${PWD}; cd /lib/systemd/system/sysinit.target.wants/; \
		ls | grep -v \
					-e dev-mqueue.mount \
					-e sys-fs-fuse-connections.mount \
					-e systemd-journald.service \
					-e systemd-tmpfiles-setup.service \
		| xargs systemctl mask $1; cd ${OLD_PWD} ) \
	&& ( export OLD_PWD=${PWD}; cd /lib/systemd/system/sockets.target.wants/; \
		ls | grep \
					-e udev \
		| xargs systemctl mask $1; cd ${OLD_PWD} )

########################################################################################

VOLUME [ "/sys/fs/cgroup", "/run", "/run/lock", "/tmp" ]

ENTRYPOINT ["/sbin/init"]
CMD ["--log-level=info"]

STOPSIGNAL SIGRTMIN+3
