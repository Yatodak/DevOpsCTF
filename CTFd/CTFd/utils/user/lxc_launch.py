import subprocess


def create_lxc_vm(username, password):
	subprocess.run(["/opt/CTFd/CTFd/utils/user/ctf.sh", username, password], check=True)
