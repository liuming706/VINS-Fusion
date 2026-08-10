#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="${VINS_WS_ROOT:-$(cd "${REPO_ROOT}/../.." && pwd)}"

ROSA_SETUP="${ROSA_SETUP:-/opt/rosa/setup.bash}"
CV_BRIDGE_PREFIX="${CV_BRIDGE_PREFIX:-/home/ubt/workspace/t800_ws/src/vnav_integration/install_x86/cv_bridge}"
INSTALL_BASE="${VINS_INSTALL_BASE:-${WORKSPACE_ROOT}/install}"
CONFIG_FILE=""
ENABLE_LOOP=0
ENABLE_GLOBAL=0

usage()
{
    cat <<EOF
用法：
  $(basename "$0") [选项] <config.yaml>

选项：
  -c, --config FILE  VINS 配置文件；也可直接作为最后一个位置参数传入
  -l, --loop         同时启动 loop_fusion_node
  -g, --global       同时启动 global_fusion_node
  -h, --help         显示帮助

示例：
  $(basename "$0") ${REPO_ROOT}/config/euroc/euroc_stereo_imu_config.yaml
  $(basename "$0") --loop ${REPO_ROOT}/config/euroc/euroc_stereo_imu_config.yaml
  $(basename "$0") --loop --global ${REPO_ROOT}/config/webots/webots_stereo_imu_config.yaml
EOF
}

while (($# > 0)); do
    case "$1" in
        -c|--config)
            [[ $# -ge 2 ]] || { echo "错误：$1 缺少参数" >&2; exit 2; }
            CONFIG_FILE="$2"
            shift 2
            ;;
        -l|--loop)
            ENABLE_LOOP=1
            shift
            ;;
        -g|--global)
            ENABLE_GLOBAL=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "错误：未知选项 $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ -n "${CONFIG_FILE}" ]]; then
                echo "错误：只能指定一个配置文件" >&2
                exit 2
            fi
            CONFIG_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "${CONFIG_FILE}" ]]; then
    echo "错误：请指定 VINS 配置文件。" >&2
    usage >&2
    exit 2
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "错误：配置文件不存在：${CONFIG_FILE}" >&2
    exit 1
fi
CONFIG_FILE="$(realpath "${CONFIG_FILE}")"

if [[ ! -f "${ROSA_SETUP}" ]]; then
    echo "错误：未找到 ROSA 环境脚本：${ROSA_SETUP}" >&2
    exit 1
fi

if [[ ! -f "${INSTALL_BASE}/setup.bash" ]]; then
    echo "错误：未找到编译安装环境：${INSTALL_BASE}/setup.bash" >&2
    echo "请先执行 ${SCRIPT_DIR}/build_rosa.sh" >&2
    exit 1
fi

ORIGINAL_SHELL="${SHELL-}"
export SHELL=/bin/bash
set +u
source "${ROSA_SETUP}"
source "${INSTALL_BASE}/setup.bash"
set -u
if [[ -n "${ORIGINAL_SHELL}" ]]; then
    export SHELL="${ORIGINAL_SHELL}"
else
    unset SHELL
fi

export CMAKE_PREFIX_PATH="${CV_BRIDGE_PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export LD_LIBRARY_PATH="${CV_BRIDGE_PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

PIDS=()

cleanup()
{
    local alive
    local attempt
    local pid

    trap - EXIT INT TERM
    for pid in "${PIDS[@]}"; do
        kill -INT "${pid}" 2>/dev/null || true
    done

    for attempt in {1..30}; do
        alive=0
        for pid in "${PIDS[@]}"; do
            if kill -0 "${pid}" 2>/dev/null; then
                alive=1
            fi
        done
        ((alive == 0)) && break
        sleep 0.1
    done

    for pid in "${PIDS[@]}"; do
        if kill -0 "${pid}" 2>/dev/null; then
            kill -TERM "${pid}" 2>/dev/null || true
        fi
    done

    sleep 0.2
    for pid in "${PIDS[@]}"; do
        if kill -0 "${pid}" 2>/dev/null; then
            kill -KILL "${pid}" 2>/dev/null || true
        fi
    done

    for pid in "${PIDS[@]}"; do
        wait "${pid}" 2>/dev/null || true
    done
}

start_node()
{
    echo "+ $*"
    "$@" &
    PIDS+=("$!")
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "配置文件：${CONFIG_FILE}"
start_node rosa run vins vins_node "${CONFIG_FILE}"

if ((ENABLE_LOOP)); then
    start_node rosa run loop_fusion loop_fusion_node "${CONFIG_FILE}"
fi

if ((ENABLE_GLOBAL)); then
    start_node rosa run global_fusion global_fusion_node
fi

echo "节点已启动，按 Ctrl-C 退出。"
set +e
wait -n "${PIDS[@]}"
STATUS=$?
set -e
exit "${STATUS}"
