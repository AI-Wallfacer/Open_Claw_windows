FROM ghcr.io/openclaw/openclaw:main

USER root

# 基础工具：jq / ffmpeg / ripgrep / 文本处理
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
       jq \
       vim \
       less \
       ffmpeg \
       ripgrep \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Python 办公文档处理库
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends python3-pip python3-docx \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages openpyxl pandas

# npm 全局工具：clawhub（技能市场）+ summarize（内容总结）
RUN npm install -g clawhub summarize --quiet

USER node
