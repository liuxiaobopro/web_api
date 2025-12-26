# 基础镜像，基于golang的alpine镜像构建--编译阶段
FROM golang:alpine AS builder

# 全局工作目录
WORKDIR /app_build

# 环境变量
ENV GOPROXY=https://goproxy.cn,direct
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64
ENV TZ=Asia/Shanghai

# 首先只复制 go.mod 和 go.sum 文件
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 编译，使用缓存优化
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go build -ldflags="-s -w" -o main main.go

# 运行阶段
FROM alpine:latest

WORKDIR /app_run

# 使用多阶段构建，只复制必要的文件
COPY --from=builder /app_build/main /app_run/main

# 将时区设置为东八区，使用国内镜像源并合并 RUN 命令减少层数
RUN echo "https://mirrors.aliyun.com/alpine/v3.8/main/" > /etc/apk/repositories \
    && echo "https://mirrors.aliyun.com/alpine/v3.8/community/" >> /etc/apk/repositories \
    && apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata \
    && mkdir -p logs

# 设置环境变量
ENV TZ=Asia/Shanghai

# 需暴露的端口
EXPOSE 18080

# docker run命令触发的真实命令(相当于直接运行编译后的可运行文件)
CMD ["/app_run/main"]