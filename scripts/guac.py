import argparse

# Parameters configuration
parser = argparse.ArgumentParser(description="Needed Argument",formatter_class=argparse.ArgumentDefaultsHelpFormatter)
# parser.add_argument("-v", "--verbose", action="store_true", help="increase verbosity")
parser.add_argument("--create", action="store_true", help="Create account and add a connection if specified")
parser.add_argument("--delete", action="store_true", help="Delete specified account")
parser.add_argument("--add_connection", action="store_true", help="Add connection for specified user, if coupled with --create, user will be created and assigned the new connection")
parser.add_argument("--delete_connection", action="store_true", help="Delete connection for specified user")
parser.add_argument("--ip", help="Ip Address of the new connection")
parser.add_argument("-u", "--username", help="Username of the account to create or delete")
parser.add_argument("-p", "--password", help="Specify in case of account creation")
args = parser.parse_args()
config = vars(args)


# Checking if all necessary parameters as been set
if args.delete and args.create:
	parser.error("Can't use --create with --delete.")
	quit()


if args.create and (args.username is None or args.password is None):
	parser.error("--create requires --username and --password.")
	quit()


if args.add_connection and (args.username is None and args.ip is None):
	parser.error("--add-connection require --ip and --username")
	quit()


if args.delete_connection and (args.username is None and args.ip is None):
	parser.error("--delete-connection require --ip and --username")
	quit()


if args.delete and args.username is None:
	parser.error("--delete require --username.")
	quit()



# Checking if Guacamole Wrapper is installed
try:
	import guacamole
except ImportError:
	print("[Error] Python module guacamole-api-wrapper need to be installed")
	print("[Error] Please install : pip install guacamole-api-wrapper in order to run this script")
	quit()


# Configuration of the Guacamole Wrapper
session = guacamole.session("http://192.168.101.129:8080/guacamole", "mysql", "guacadmin", "guacadmin")


if not (args.create or args.delete or args.add_connection or args.delete_connection):
	print("No option Specified Displaying all users (TODO)")
	userlist = session.list_users()
	print(userlist)


###### Guacamole Interaction ######

# User creation
if args.create:
	user_attributes = { 'timezone': 'Europe/Paris' }
	createduser = session.create_user(args.username, args.password, user_attributes)
	print(createduser)


# User deletion
if args.delete:
	deleteduser = session.delete_user(args.username)
	print(deleteduser)

# Connection creation
if args.add_connection:
	userdetails = session.detail_user(args.username)
	try:
		connection_parameters = {'password': args.password, 'username': args.username, 'command': '/bin/bash', 'hostname': args.ip, 'port': 22}
		addedconnection = session.manage_connection('ssh',f"DevOpsCTF-{args.username}", parameters=connection_parameters)
		print("### Added Connection Info :", addedconnection)
		connection_id = addedconnection['identifier']
		print(connection_id)
		# Adding Permission to user
		perm = session.update_connection_permissions(args.username, connection_id, 'add', 'connection')
		print(f"Connection created and permission added to {args.username}")
	except KeyError as ke:
		print(f"User {args.username} do not exist, if you wish to create it use --create")
		quit()
