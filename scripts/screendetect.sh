#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/blackscreen-debug"
STATE_DIR="${BASE_DIR}/state"

KERNEL_LOG="${BASE_DIR}/kernel.log"
KERNEL_DRMDEBUG_LOG="${BASE_DIR}/kernel-drmdebug.log"
USER_LOG="${BASE_DIR}/user.log"
CONNECTORS_LOG="${BASE_DIR}/connectors.log"

KERNEL_PID_FILE="${STATE_DIR}/kernel.pid"
KERNEL_DRMDEBUG_PID_FILE="${STATE_DIR}/kernel-drmdebug.pid"
USER_PID_FILE="${STATE_DIR}/user.pid"
CONNECTORS_PID_FILE="${STATE_DIR}/connectors.pid"

usage() {
	cat <<'EOF'
Usage:
	screendetect.sh start [--drm-debug]
	screendetect.sh stop
	screendetect.sh status
	screendetect.sh tail

Commands:
	start         Start log capture jobs.
	--drm-debug   Also enable drm debug (0x1ff) and capture an extra kernel log.
	stop          Stop all jobs. Disables drm debug if it was enabled.
	status        Show job status and output files.
	tail          Show the last lines from all logs.
EOF
}

ensure_dirs() {
	mkdir -p "${BASE_DIR}" "${STATE_DIR}"
}

is_pid_running() {
	local pid="$1"
	kill -0 "${pid}" 2>/dev/null
}

write_pid() {
	local pid_file="$1"
	local pid="$2"
	printf '%s\n' "${pid}" > "${pid_file}"
}

read_pid() {
	local pid_file="$1"
	[[ -f "${pid_file}" ]] || return 1
	cat "${pid_file}"
}

stop_pid_file() {
	local pid_file="$1"
	if [[ -f "${pid_file}" ]]; then
		local pid
		pid="$(cat "${pid_file}")"
		if is_pid_running "${pid}"; then
			kill "${pid}" || true
		fi
		rm -f "${pid_file}"
	fi
}

start_kernel_log() {
	if [[ -f "${KERNEL_PID_FILE}" ]] && is_pid_running "$(cat "${KERNEL_PID_FILE}")"; then
		echo "kernel logger already running"
		return
	fi

	sudo nohup sh -c "journalctl -k -f -o short-precise > '${KERNEL_LOG}'" >/dev/null 2>&1 &
	write_pid "${KERNEL_PID_FILE}" "$!"
	echo "started kernel logger -> ${KERNEL_LOG}"
}

start_kernel_drmdebug_log() {
	if [[ -f "${KERNEL_DRMDEBUG_PID_FILE}" ]] && is_pid_running "$(cat "${KERNEL_DRMDEBUG_PID_FILE}")"; then
		echo "kernel drm-debug logger already running"
		return
	fi

	sudo sh -c "echo 0x1ff > /sys/module/drm/parameters/debug"
	sudo nohup sh -c "journalctl -k -f -o short-precise > '${KERNEL_DRMDEBUG_LOG}'" >/dev/null 2>&1 &
	write_pid "${KERNEL_DRMDEBUG_PID_FILE}" "$!"
	echo "enabled drm debug and started logger -> ${KERNEL_DRMDEBUG_LOG}"
}

start_user_log() {
	if [[ -f "${USER_PID_FILE}" ]] && is_pid_running "$(cat "${USER_PID_FILE}")"; then
		echo "user logger already running"
		return
	fi

	nohup sh -c "journalctl --user -f -o short-precise > '${USER_LOG}'" >/dev/null 2>&1 &
	write_pid "${USER_PID_FILE}" "$!"
	echo "started user logger -> ${USER_LOG}"
}

start_connectors_log() {
	if [[ -f "${CONNECTORS_PID_FILE}" ]] && is_pid_running "$(cat "${CONNECTORS_PID_FILE}")"; then
		echo "connectors logger already running"
		return
	fi

	nohup sh -c '
		while true; do
			date --iso-8601=ns
			for s in /sys/class/drm/card*-*/status; do
				printf "%s: " "$s"
				cat "$s"
			done
			echo
			sleep 1
		done
	' > "${CONNECTORS_LOG}" 2>/dev/null &
	write_pid "${CONNECTORS_PID_FILE}" "$!"
	echo "started connectors logger -> ${CONNECTORS_LOG}"
}

cmd_start() {
	local drm_debug="false"
	if [[ "${1:-}" == "--drm-debug" ]]; then
		drm_debug="true"
	elif [[ -n "${1:-}" ]]; then
		usage
		exit 1
	fi

	ensure_dirs
	start_kernel_log
	start_user_log
	start_connectors_log

	if [[ "${drm_debug}" == "true" ]]; then
		start_kernel_drmdebug_log
	fi
}

cmd_stop() {
	stop_pid_file "${KERNEL_PID_FILE}"
	stop_pid_file "${KERNEL_DRMDEBUG_PID_FILE}"
	stop_pid_file "${USER_PID_FILE}"
	stop_pid_file "${CONNECTORS_PID_FILE}"

	sudo sh -c "echo 0 > /sys/module/drm/parameters/debug" || true
	echo "stopped all loggers"
}

show_pid_status() {
	local name="$1"
	local pid_file="$2"

	if [[ -f "${pid_file}" ]]; then
		local pid
		pid="$(cat "${pid_file}")"
		if is_pid_running "${pid}"; then
			echo "${name}: running (pid ${pid})"
		else
			echo "${name}: stale pid file (pid ${pid})"
		fi
	else
		echo "${name}: not running"
	fi
}

cmd_status() {
	show_pid_status "kernel" "${KERNEL_PID_FILE}"
	show_pid_status "kernel-drmdebug" "${KERNEL_DRMDEBUG_PID_FILE}"
	show_pid_status "user" "${USER_PID_FILE}"
	show_pid_status "connectors" "${CONNECTORS_PID_FILE}"

	echo
	echo "logs:"
	echo "  ${KERNEL_LOG}"
	echo "  ${KERNEL_DRMDEBUG_LOG}"
	echo "  ${USER_LOG}"
	echo "  ${CONNECTORS_LOG}"
}

cmd_tail() {
	for f in "${KERNEL_LOG}" "${KERNEL_DRMDEBUG_LOG}" "${USER_LOG}" "${CONNECTORS_LOG}"; do
		echo "===== ${f} ====="
		if [[ -f "${f}" ]]; then
			tail -n 60 "${f}"
		else
			echo "(missing)"
		fi
		echo
	done
}

main() {
	local cmd="${1:-}"
	case "${cmd}" in
		start)
			shift
			cmd_start "$@"
			;;
		stop)
			cmd_stop
			;;
		status)
			cmd_status
			;;
		tail)
			cmd_tail
			;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
