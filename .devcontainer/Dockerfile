ARG DEBIAN_VERSION=bullseye
ARG DOCKER_VERSION=20.10.2
ARG DOCKER_COMPOSE_VERSION=debian-1.28.4
ARG GOLANG_VERSION=1.19
ARG GOLANGCI_LINT_VERSION=v1.37.1

FROM docker:${DOCKER_VERSION} AS docker-cli
FROM docker/compose:${DOCKER_COMPOSE_VERSION} AS docker-compose
FROM golangci/golangci-lint:${GOLANGCI_LINT_VERSION} as golangci-lint

FROM golang:${GOLANG_VERSION}-${DEBIAN_VERSION}

# Configure to avoid build warnings and errors as described in official VSCode Remote-Containers extension documentation.
# See https://code.visualstudio.com/docs/remote/containers-advanced#_reducing-dockerfile-build-warnings.
ENV DEBIAN_FRONTEND=noninteractive
# CA certificates
RUN apt-get update -y && \
    # CA certificates
    apt-get install -y --no-install-recommends ca-certificates && \
    # Timezone
    apt-get install -y --no-install-recommends tzdata && \
    # Setup Git and SSH
    apt-get install -y --no-install-recommends git openssh-client && \
    # Setup sudo
    apt-get install -y --no-install-recommends sudo && \
    # Setup shell
    apt-get install -y --no-install-recommends zsh nano locales && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -r /var/cache/* /var/lib/apt/lists/*

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

ENV TZ=
WORKDIR /home/${USERNAME}
RUN addgroup --gid $USER_GID $USERNAME && \
    useradd $USERNAME --shell /bin/sh --uid $USER_UID --gid $USER_GID && \
    mkdir -p /etc/sudoers.d && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    rm /var/log/faillog /var/log/lastlog

# Setup shell for root and ${USERNAME}
ENTRYPOINT [ "/bin/zsh" ]


ENV EDITOR=nano \
    LANG=en_US.UTF-8 \
    # MacOS compatibility
    TERM=xterm

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8

RUN usermod --shell /bin/zsh root && \
    usermod --shell /bin/zsh ${USERNAME}

COPY --chown=${USER_UID}:${USER_GID} shell/.p10k.zsh shell/.zshrc shell/.welcome.sh /home/${USERNAME}/

RUN ln -s /home/${USERNAME}/.p10k.zsh /root/.p10k.zsh && \
    cp /home/${USERNAME}/.zshrc /root/.zshrc && \
    cp /home/${USERNAME}/.welcome.sh /root/.welcome.sh && \
    sed -i "s/HOMEPATH/home\/${USERNAME}/" /home/${USERNAME}/.zshrc && \
    sed -i "s/HOMEPATH/root/" /root/.zshrc

ARG POWERLEVEL10K_VERSION=v1.14.6

RUN git clone --single-branch --depth 1 https://github.com/robbyrussell/oh-my-zsh.git /home/${USERNAME}/.oh-my-zsh && \
    git clone --branch ${POWERLEVEL10K_VERSION} --single-branch --depth 1 https://github.com/romkatv/powerlevel10k.git /home/${USERNAME}/.oh-my-zsh/custom/themes/powerlevel10k && \
    rm -rf /home/${USERNAME}/.oh-my-zsh/custom/themes/powerlevel10k/.git && \
    chown -R ${USERNAME}:${USER_GID} /home/${USERNAME} && \
    chmod -R 700 /home/${USERNAME} && \
    cp -r /home/${USERNAME}/.oh-my-zsh /root/.oh-my-zsh && \
    chown -R root:root /root/.oh-my-zsh

ENV ZSH=/home/${USERNAME}/.oh-my-zsh

RUN git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH/plugins/zsh-autosuggestions

RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH/plugins/zsh-syntax-highlighting

# Docker
COPY --from=docker-cli --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-compose --chown=${USER_UID}:${USER_GID} /usr/local/bin/docker-compose /usr/local/bin/docker-compose
ENV DOCKER_BUILDKIT=1 \
    COMPOSE_DOCKER_CLI_BUILD=1
# All possible docker host groups
RUN G102=`getent group 102 | cut -d":" -f 1` && \
    G976=`getent group 976 | cut -d":" -f 1` && \
    G1000=`getent group 1000 | cut -d":" -f 1` && \
    if [ -z $G102 ]; then G102=docker102; addgroup --gid 102 $G102; fi && \
    if [ -z $G976 ]; then G976=docker976; addgroup --gid 976 $G976; fi && \
    if [ -z $G1000 ]; then G1000=docker1000; addgroup --gid 1000 $G1000; fi && \
    addgroup ${USERNAME} $G102 && \
    addgroup ${USERNAME} $G976 && \
    addgroup ${USERNAME} $G1000

RUN apt-get update -y \
    && apt-get -y install --no-install-recommends apt-utils 2>&1 \
    # Verify git, process tools, lsb-release (common in install instructions for CLIs) installed.
    && apt-get -y install git iproute2 procps lsb-release \
    # Install Python
    && apt-get install -y python3 python3-pip unzip \
    && apt-get install -y protobuf-compiler \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN git config --global gpg.program /usr/bin/gpg

ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p ${GOPATH}/src/github.com && \
    chown -R ${USER_UID}:${USER_GID} ${GOPATH}

USER ${USERNAME}

COPY --from=golangci-lint /usr/bin/golangci-lint ${GOPATH}/bin
RUN go install golang.org/x/tools/gopls@latest 2>&1
# Base Go tools needed for VS code Go extension
RUN go install golang.org/x/tools/cmd/guru@latest
RUN go install golang.org/x/tools/cmd/gorename@latest
RUN go install github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest
RUN go install github.com/fatih/gomodifytags@latest
RUN go install github.com/haya14busa/goplay/cmd/goplay@latest
RUN go install github.com/davidrjenni/reftools/cmd/fillstruct@latest
RUN go install github.com/golang/mock/mockgen@latest
RUN go install github.com/vektra/mockery/v2@latest

USER root

# Revert configurations that was set at top layer (for avoiding build warnings and errors).
ENV DEBIAN_FRONTEND=dialog

USER ${USERNAME}

# Expose service ports.
EXPOSE 8000

