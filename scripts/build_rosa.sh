#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="${VINS_WS_ROOT:-$(cd "${REPO_ROOT}/../.." && pwd)}"

ROSA_SETUP="${ROSA_SETUP:-/opt/rosa/setup.bash}"
CV_BRIDGE_PREFIX="${CV_BRIDGE_PREFIX:-/home/ubt/workspace/t800_ws/src/vnav_integration/install_x86/cv_bridge}"
BUILD_BASE="${VINS_BUILD_BASE:-${WORKSPACE_ROOT}/build}"
INSTALL_BASE="${VINS_INSTALL_BASE:-${WORKSPACE_ROOT}/install}"
LOG_BASE="${VINS_LOG_BASE:-${WORKSPACE_ROOT}/log}"
BUILD_TYPE="${VINS_BUILD_TYPE:-RelWithDebInfo}"
PARALLEL_WORKERS="${VINS_BUILD_JOBS:-4}"

if [[ ! -f "${ROSA_SETUP}" ]]; then
	echo "错误：未找到 ROSA 环境脚本：${ROSA_SETUP}" >&2
	exit 1
fi

if [[ ! -f "${CV_BRIDGE_PREFIX}/share/cv_bridge/cmake/cv_bridgeConfig.cmake" ]]; then
	echo "错误：未找到 ROSA cv_bridge：${CV_BRIDGE_PREFIX}" >&2
	echo "可通过 CV_BRIDGE_PREFIX 指定其安装前缀。" >&2
	exit 1
fi

ORIGINAL_SHELL="${SHELL-}"
export SHELL=/bin/bash
set +u
source "${ROSA_SETUP}"
set -u
if [[ -n "${ORIGINAL_SHELL}" ]]; then
	export SHELL="${ORIGINAL_SHELL}"
else
	unset SHELL
fi

export CMAKE_PREFIX_PATH="${CV_BRIDGE_PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export LD_LIBRARY_PATH="${CV_BRIDGE_PREFIX}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

echo "VINS-Fusion ROSA 编译配置："
echo "  源码目录：${REPO_ROOT}"
echo "  构建目录：${BUILD_BASE}"
echo "  安装目录：${INSTALL_BASE}"
echo "  日志目录：${LOG_BASE}"
echo "  构建类型：${BUILD_TYPE}"
echo "  并行任务：${PARALLEL_WORKERS}"

colcon --log-base "${LOG_BASE}" build \
	--base-paths "${REPO_ROOT}" \
	--build-base "${BUILD_BASE}" \
	--install-base "${INSTALL_BASE}" \
	--executor parallel \
	--parallel-workers "${PARALLEL_WORKERS}" \
	--event-handlers console_cohesion+ \
	--mixin compile-commands \
	--cmake-args "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"

echo
echo "编译完成。加载运行环境："
echo "  source ${INSTALL_BASE}/setup.bash"
