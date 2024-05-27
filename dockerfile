# 设置基础镜像UBUNTU_VERSION变量，默认值为24.04
ARG UBUNTU_VERSION="24.04"
# 使用变量UBUNTU_VERSION指定基础镜像，并设置别名为system
FROM ubuntu:${UBUNTU_VERSION} as system

# 设置镜像的维护者信息
LABEL maintainer="ReLucy"

# 镜像暴露22和8000端口，分别是SSH和通常用于Web应用的端口
EXPOSE 22 8000
# 配置环境变量，设置语言和时区
ENV LANG=C.UTF-8 \
    TZ=Asia/Shanghai

# 设置工作目录为/root
WORKDIR /root

# 将宿主机的./init/startupService.sh和./init/setPassword.sh文件拷贝到容器的/root/目录，并设置所有者为root
COPY --chown=root:root ./init/startupService.sh ./init/setPassword.sh /root/

# 安装必要软件包，设置时区，安装openssh-server等，允许root用户登录SSH，并设置一些启动脚本
# 在同一RUN命令中执行更新、安装和清理缓存的命令以减少镜像层次
RUN export DEBIAN_FRONTEND=noninteractive \
    && cp -a /etc/apt/sources.list /etc/apt/sources.list.bak \
    && sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list \
    && sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && sed -i "s@http@https@g" /etc/apt/sources.list \
    && apt-get update && apt full-upgrade -y \
    && apt-get install -y tzdata \
    && echo "${TZ}" > /etc/timezone && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && apt-get update \
    && apt-get install -y --no-install-recommends openssh-server vim net-tools iputils-ping traceroute curl wget git gnupg ca-certificates sudo build-essential \
    && sed -i "/PermitRootLogin prohibit-password/a\PermitRootLogin yes" /etc/ssh/sshd_config \
    && chmod +x /root/setPassword.sh \
    && chmod +x /root/startupService.sh \
    && sed -i '$a\if [ -f /root/startupService.sh ]; then' /root/.bashrc \
    && sed -i '$a\    . /root/startupService.sh' /root/.bashrc \
    && sed -i '$a\fi' /root/.bashrc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置容器启动时执行的命令
CMD ["/bin/bash", "-c", "/etc/init.d/ssh start && tail -f /dev/null"]

# 从前面命名为system的镜像层开始构建新的镜像层，并设置别名为anaconda
FROM system as anaconda

# 配置Anaconda安装目录的环境变量在Anaconda安装后设置
# 安装Anaconda，然后创建名为one的conda环境并安装PyTorch等包
RUN wget https://repo.anaconda.com/archive/Anaconda3-2021.11-Linux-x86_64.sh && \
    bash Anaconda3-2021.11-Linux-x86_64.sh -b -p /root/anaconda3 && \
    rm Anaconda3-2021.11-Linux-x86_64.sh && \
    echo 'export PATH=/root/anaconda3/bin:$PATH' >> /root/.bashrc && \
    /bin/bash -c "source /root/anaconda3/bin/activate && \
    conda create -n one python=3.10 anaconda && \
    conda activate one && \
    conda install -y pytorch torchvision torchaudio cudatoolkit=11.3 -c pytorch && \
    conda deactivate"

ENV PATH="/root/anaconda3/bin:${PATH}"

# 将宿主机的./init/motd文件拷贝到容器的/etc/目录
COPY --chown=root:root ./init/motd /etc/
