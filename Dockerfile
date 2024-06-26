################################################################################
# base system
################################################################################

FROM ubuntu:22.04 AS system

# Avoid prompts for time zone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo
# Fix issue with libGL on Windows
ENV LIBGL_ALWAYS_INDIRECT=1

# built-in packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y apt-utils software-properties-common curl apache2-utils \
        supervisor nginx sudo net-tools zenity dbus-x11 x11-utils alsa-utils \
        mesa-utils wget xvfb x11vnc vim-tiny ttf-wqy-zenhei lxde gtk2-engines-murrine \
        arc-theme python3 python3-tk gcc make cmake python3-pip python3-dev build-essential \
        nano git zsh htop locales man git-lfs procps openssh-client vim.tiny lsb-release python3-zope.interface \
        iputils-ping pkg-config

RUN git lfs install && \
    sed -i "s/# en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8

RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null

# tini to fix subreap
ARG TINI_VERSION=v0.19.0
RUN wget https://github.com/krallin/tini/archive/v0.19.0.tar.gz \
 && tar zxf v0.19.0.tar.gz \
 && export CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"; \
    cd tini-0.19.0; cmake . && make && make install \
 && cd ..; rm -r tini-0.19.0 v0.19.0.tar.gz


# Firefox with apt, not snap (which does not run in the container)
COPY mozilla-firefox_aptprefs.txt /etc/apt/preferences.d/mozilla-firefox
RUN add-apt-repository -y ppa:mozillateam/ppa

# Chromium beta with apt, not snap (which does not run in the container)
COPY chromium_aptprefs.txt /etc/apt/preferences.d/chromium
RUN sudo add-apt-repository -y ppa:saiarcot895/chromium-beta

RUN apt-get update && \
    apt-get install -y --allow-downgrades chromium-browser firefox fonts-lyx

RUN sed -i 's/Exec=chromium-browser %U/Exec=chromium-browser %U --no-sandbox/g' /usr/share/applications/chromium-browser.desktop

# Killsession app
COPY killsession/ /tmp/killsession
RUN cd /tmp/killsession; \
    gcc -o killsession killsession.c && \
    mv killsession /usr/local/bin && \
    chmod a=rx /usr/local/bin/killsession && \
    chmod a+s /usr/local/bin/killsession && \
    mv killsession.py /usr/local/bin/ && chmod a+x /usr/local/bin/killsession.py && \
    mkdir -p /usr/local/share/pixmaps && mv killsession.png /usr/local/share/pixmaps/ && \
    mv KillSession.desktop /usr/share/applications/ && chmod a+x /usr/share/applications/KillSession.desktop && \
    cd /tmp && rm -r killsession
    

# python library
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN dpkg-query -W -f='${Package}\n' > /tmp/a.txt \
    && pip3 install -r /tmp/requirements.txt \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && dpkg-query -W -f='${Package}\n' > /tmp/b.txt

# RUN apt purge -y deluge xscreensaver bc light-locker evince lxmusic smplayer yelp bluez cups

RUN apt-get remove -y `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs` && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/* /tmp/a.txt /tmp/b.txt


################################################################################
# builder
################################################################################
FROM ubuntu:22.04 AS builder

RUN apt-get update \
    && apt-get install -y curl ca-certificates gnupg

# nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs

# yarn
RUN curl -fs https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/yarnpkg_pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn

# build frontend
COPY web /src/web
RUN cd /src/web \
    && yarn upgrade \
    && yarn \
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js

# RUN apt autoremove && apt autoclean

################################################################################
# merge
################################################################################
FROM system
# LABEL maintainer="frederic.boulanger@centralesupelec.fr"

COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify && \
	chmod +x /usr/local/lib/web/frontend/static/websockify/run

EXPOSE 80
WORKDIR /root

RUN wget https://github.com/MuhammedKalkan/OpenLens/releases/download/v6.5.2-366/OpenLens-6.5.2-366.$(dpkg --print-architecture).deb -O openlens.deb && \
    dpkg -i openlens.deb && \
    rm openlens.deb

RUN wget https://github.com/coder/code-server/releases/download/v4.90.3/code-server_4.90.3_$(dpkg --print-architecture).deb -O code.deb && \
    dpkg -i code.deb && \
    rm code.deb

ENV HOME=/home/ubuntu \
    SHELL=/bin/zsh
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
