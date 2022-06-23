#!/usr/bin/env python3
import argparse
import os
import pathlib
import re
import subprocess
import uuid

import requests

_RUNNER_REGEX = re.compile("^actions-runner-linux-x64-[0-9]+\\.[0-9]+\\.[0-9]+\\.tar\\.gz$")
_SCRIPT_DIRECTORY = pathlib.Path(__file__).parent

def _parse_arguments():
	parser = argparse.ArgumentParser(description="Starts the runner.")
	parser.add_argument("--detach", help="Start the runner in the background.", action="store_true")
	parser.add_argument("--insecure", help="Disable SSL certificate verification.", action="store_true")
	parser.add_argument("--offline", help="Disable access to GitHub.com.", action="store_true")
	return parser.parse_known_args()

def main():
	arguments, runner_arguments = _parse_arguments()

	latest_runner_response = requests.get("https://api.github.com/repos/actions/runner/releases/latest")
	latest_runner_response.raise_for_status()
	for asset in latest_runner_response.json()["assets"]:
		if _RUNNER_REGEX.match(asset["name"]):
			runner_url = asset["browser_download_url"]
			break
	else:
		raise Exception("Could not find a runner download for the latest release.")

	subprocess.check_call(
		[
			"docker", "build",
			"--tag", "actions-runner",
			"--build-arg", f"runner_url={runner_url}",
			".",
		],
		cwd=_SCRIPT_DIRECTORY,
	)

	name = f"actions-runner-{uuid.uuid4()}"

	docker_arguments = ["docker", "run"]
	if arguments.detach:
		docker_arguments += ["--detach"]
	else:
		docker_arguments += ["--interactive", "--tty"]

	docker_arguments += ["--name", name]
	docker_arguments += ["--net", "host"]
	docker_arguments += ["--add-host", "pipelines.codedev.ms:127.0.0.1"]

	if arguments.insecure:
		docker_arguments += ["--env", "DISABLE_SSL=true"]
	if arguments.offline:
		docker_arguments += ["--add-host", "github.com:127.0.0.1"]

	docker_arguments += ["actions-runner"]

	runner_arguments += ["--disableupdate", "--unattended", "--name", name]

	os.execvp(docker_arguments[0], docker_arguments + runner_arguments)

if __name__ == "__main__":
	main()
