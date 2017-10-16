///
module kaleidic.api.lxc.container;
/**
	LXC-D: D Language Wrapper for LXC Linux Containers

	(C) 2017 by Laeeth Isharc and Kaleidic Associates Advisory Limited

	MIT Licensed

	This is a very early version and not at all tested - use at your own peril.
*/


import core.stdc.config;
import core.sys.posix.stdlib;
import core.sys.posix.sys.types;

import std.string:toStringz, fromStringz;
import std.array:array;
import std.exception:enforce;

import deimos.lxc.attach_options;
import deimos.lxc.lxclock;
import deimos.lxc.lxccontainer;

///
extern (C) nothrow @nogc
{
	///
	struct lxc_log {}
	///
	int lxc_log_init(lxc_log* log);
	///
	int lxc_attach_run_command(void* payload);
	///
	int lxc_attach_run_shell(void* payload);

	///
	struct lxc_attach_command_t
	{
		char* program;
		char**args;
	}
	///
	alias lxc_attach_exec_t = int function(void* payload);
}

private const(char*) toStringzc(string s)
{
	return cast(const(char*)) s.toStringz;
}

private string[] fromCArray(char** arr)
{
	string[] ret;
	if (arr is null)
		return ret;
	auto p = arr;
	while((*p) ! is null)
	{
		ret~=(*p).fromStringz.idup;
		p=arr+1;
	}
	return ret;
}

private const(char*)* toCArray(string[] arr)
{
	import std.algorithm:map;
	import std.array:array;
	auto ret = arr.map!(entry => entry.toStringzc).array;
	return ret.ptr;
}


///
enum OpStatus
{
	success,
	failure,
}

///
struct LXCContainer
{
	import std.algorithm:map;
	import core.time:Duration;
	import std.conv:to;

	///
	lxc_container* container;
	
	///
	this(string name, string configPath = null)
	{
		auto configpath = (configPath is null ) ? null : configPath.toStringzc;
		this.container = lxc_container_new(name.toStringzc,configpath);
		enforce(this.container !is null, "unable to create new LXC container "~ name~ ":" ~configPath);
		this.addRef();
	}

	///
	this(lxc_container* container)
	{
		this.container = container;
	}

	///
	~this()
	{
		dropRef();
	}

	///
	string name()
	{
		auto ret = this.container.name;
		return (ret is null) ?  null : ret.fromStringz.idup;
	}

	///
	string configFile()
	{
		return (this.container.configfile is null) ? null : this.container.configfile.fromStringz.idup;
	}

	///
	string pidFile()
	{
		return (this.container.pidfile is null) ? null : this.container.pidfile.fromStringz.idup;
	}
	
	///
	bool isDefined()
	{
		return (this.container.is_defined(this.container));
	}
	
	///
	string state()
	{
		return (this.container.state is null) ? null : this.container.state(container).fromStringz.idup;
	}

	///
	bool isRunning()
	{
		return (this.container.is_running(this.container));
	}

	///
	OpStatus freeze()
	{
		return this.container.freeze(this.container) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus unfreeze()
	{
		return this.container.unfreeze(this.container) ? OpStatus.success : OpStatus.failure;
	}

	///
	pid_t initPid()
	{
		return this.container.init_pid(this.container);
	}

	///
	OpStatus loadConfig(string filename)
	{
		return this.container.load_config(this.container,filename.toStringzc) ? OpStatus.success: OpStatus.failure;
	}

	///
	OpStatus start(bool useInit = false,string[] args=cast(string[])[])
	{
		auto cArgs = args.map!(arg=>arg.toStringzc).array;
		return this.container.start(this.container,useInit,cArgs.ptr) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus stop()
	{
		return this.container.stop(this.container) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus wantDaemonize(bool daemonize = true)
	{
		return this.container.want_daemonize(this.container,daemonize ? 1 : 0) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus wantCloseAllFDs(bool closeAll = true)
	{
		return this.container.want_close_all_fds(this.container,closeAll ? 1 : 0) ? OpStatus.success : OpStatus.failure;
	}

	///
	string configFileName()
	{
		return this.container.config_file_name(this.container,).fromStringz.idup;
	}

	///
	OpStatus wait(string state, Duration timeout)
	{
		return this.container.wait(this.container,state.toStringzc, timeout.total!"seconds".to!int) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus setConfigItem(string key, string value)
	{
		return this.container.set_config_item(this.container,key.toStringzc, value.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus destroy()
	{
		return this.container.destroy(this.container) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus saveConfig(string altFile)
	{
			return this.container.save_config(this.container,altFile.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus create(string t, string bdevType, BackingDeviceSpec specs, CreateFlags flags, string[] args)
	{
		return this.container.create(this.container,t.toStringzc, bdevType.toStringzc, specs.specs, flags.to!int, args.toCArray) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus rename(string newName)
	{
		return this.container.rename(this.container,newName.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus reboot()
	{
		return this.container.reboot(this.container,) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus shutdown(Duration timeout)
	{
		return this.container.shutdown(this.container,timeout.total!"seconds".to!int) ? OpStatus.success : OpStatus.failure;
	}

	///
	void clearConfig()
	{
		this.container.clear_config(this.container);
	}
	
	///
	OpStatus clearConfigItem(string key)
	{
		return this.container.clear_config_item(this.container,key.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	string getConfigItem(string key)
	{
		char[] retv;
		auto result = this.container.get_config_item(this.container,key.toStringzc, null,0);
		retv.length = result+1;
		result = this.container.get_config_item(this.container,key.toStringzc, retv.ptr, retv.length.to!int);
		return retv.idup;
	}

	///
	string getRunningConfigItem(string key)
	{
		auto ret = this.container.get_running_config_item(this.container,key.toStringzc);
		return (ret is null) ? null : ret.fromStringz.idup;
	}

	///
	string getKeys(string keyPrefix)
	{
		char[] ret;
		auto result = this.container.get_keys(this.container,keyPrefix.toStringzc,null,0);
		if (result<=0 )
			return null;
		result = this.container.get_keys(this.container,keyPrefix.toStringzc, ret.ptr, ret.length.to!int);
		return ret.idup;
	}

	///
	string[] getInterfaces()
	{
		string[] ret;
		auto result = this.container.get_interfaces(this.container);
		ret = (result is null) ? ret : result.fromCArray;
		return ret;
	}

	///
	string[] getIPs(string interfaceString, string family, int scopeID)
	{
		string[] ret;
		auto result = this.container.get_ips(this.container,interfaceString.toStringzc, family.toStringzc, scopeID);
		ret = (result is null) ? ret : result.fromCArray;
		return ret;
	}

	///
	string getCGroupItem(string subsys)
	{
		char[] ret;
		auto result = this.container.get_cgroup_item(this.container,subsys.toStringzc,null,0);
		if (result<=0)
			return null;
		ret.length = result;
		result = this.container.get_cgroup_item(this.container,subsys.toStringzc,ret.ptr,ret.length.to!int);
		return ret.idup;
	}

	///
	OpStatus setCGroupItem(string subsys, string value)
	{
		return this.container.set_cgroup_item(this.container,subsys.toStringzc, value.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	string getConfigPath()
	{
		return this.container.get_config_path(this.container).fromStringz.idup;
	}

	///
	OpStatus setConfigPath(string path)
	{
		return this.container.set_config_path(this.container,path.toStringzc) ? OpStatus.success:OpStatus.failure;
	}


	///
	LXCContainer clone(string newName, string lxcPath, int flags, string bDevType, ubyte[] bDevData, ulong newSize, string[] hookArgs)
	{
		auto result = this.container.clone(this.container,newName.toStringzc,lxcPath.toStringzc,flags,bDevType.toStringzc,cast(char*) bDevData.ptr,newSize, cast(char**)hookArgs.toCArray);
		return LXCContainer(result);
	}
	

	///
	auto consoleGetFD()
	{
		import std.typecons:tuple;
		int ttyNum, masterFD;
		auto status =  this.container.console_getfd(this.container,&ttyNum, &masterFD)  ? OpStatus.success : OpStatus.failure;
		return tuple(status,ttyNum,masterFD);
	}

	///
	OpStatus console(int ttyNum, int stdinfd, int stdoutfd, int stderrfd, int escape)
	{
		return this.container.console(this.container,ttyNum, stdinfd, stdoutfd, stderrfd, escape) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus attach(lxc_attach_exec_t execFunction, void* execPayload, AttachOptions attachOptions, pid_t* attachedProcess)
	{
		return this.container.attach(this.container,execFunction, execPayload, attachOptions.options, attachedProcess) ? OpStatus.success : OpStatus.failure;
	}
	// int function(lxc_container* c, lxc_attach_exec_t exec_function, void* exec_payload, lxc_attach_options_t* options, pid_t* attached_process) attach;


	///
	OpStatus attachRunWait(AttachOptions attachOptions, string program, string[] args)
	{
		return this.container.attach_run_wait(this.container,attachOptions.options, program.toStringzc, args.toCArray) ? OpStatus.success : OpStatus . failure;
	}


	///
	OpStatus snapShot(string commentFile)
	{
		return this.container.snapshot(this.container,commentFile.toStringzc) ? OpStatus.success : OpStatus.failure;
	}


	///
	SnapShot[] listSnapshots()
	{
		lxc_snapshot*[] snapshots;
		auto result = this.container.snapshot_list(this.container,null);
		if (result<=0)
			return snapshots.map!(snapshot=>SnapShot(snapshot)).array;
		snapshots.length = result;
		result = this.container.snapshot_list(this.container,snapshots.ptr);
		enforce(snapshots.length == result);
		return snapshots.map!(snapshot=> SnapShot(snapshot)).array;
	}

	///
	OpStatus snapshotRestore(string snapName, string newName)
	{
		return this.container.snapshot_restore(this.container,snapName.toStringzc, newName.toStringzc) ? OpStatus.success : OpStatus.failure;
	}
	
	///
	OpStatus snapshotDestroy(string name)
	{
		return this.container.snapshot_destroy(this.container,name.toStringzc) ? OpStatus.success: OpStatus.failure;
	}

	///
	bool mayControl()
	{
		return this.container.may_control(this.container);
	}
	
	///
	OpStatus addDeviceNode(string sourcePath, string destPath)
	{
		return this.container.add_device_node(this.container,sourcePath.toStringzc, destPath.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus removeDeviceNode(string sourcePath, string destPath)
	{
		return this.container.remove_device_node(this.container,sourcePath.toStringzc, destPath.toStringzc) ? OpStatus.success : OpStatus.failure;
	}
	
	///
	OpStatus attachInterface(string dev, string destDev)
	{
		return this.container.attach_interface(this.container,dev.toStringzc, destDev.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus detachInterface(string dev, string destDev)
	{
		return this.container.detach_interface(this.container,dev.toStringzc, destDev.toStringzc) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus checkpoint(string directory, bool stop, bool verbose = false)
	{
		// deimos should declare directory as const(char*)
		return this.container.checkpoint(this.container,cast(char*) directory.toStringzc, stop,verbose) ? OpStatus.success: OpStatus.failure;
	}

	///
	OpStatus restore(string directory, bool verbose = false)
	{
		// deimos should declare directory as const(char*)
		return this.container.restore(this.container,cast(char*)directory.toStringzc,verbose) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus destroyWithSnapshots()
	{
		return this.container.destroy_with_snapshots(this.container) ? OpStatus.success : OpStatus.failure;
	}
	
	///
	OpStatus snaphotDestroyAll()
	{
		return this.container.snapshot_destroy_all(this.container) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus migrate(MigrateCommand command, MigrateOptions migrateOptions, uint size)
	{
		return this.container.migrate(this.container,command.to!uint, migrateOptions.options, size) ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus addRef()
	{
		return this.container.lxc_container_get() ? OpStatus.success : OpStatus.failure;
	}

	///
	OpStatus dropRef()
	{
		return this.container.lxc_container_put() ? OpStatus.success : OpStatus.failure;		
	}
}


	///
struct SnapShot
{
	///
	lxc_snapshot* snapshot;

	///
	string name()
	{
		return this.snapshot.name.fromStringz.idup;
	}

	///
	string commentPathName()
	{
		return this.snapshot.comment_pathname.fromStringz.idup;
	}

	///
	string timeStamp()
	{
		return this.snapshot.timestamp.fromStringz.idup;
	}

	///
	string name()
	{
		return this.snapshot.name.fromStringz.idup;
	}

	///
	string commentPathName()
	{
		return this.snapshot.comment_pathname.fromStringz.idup;
	}

	///
	string lxcPath()
	{
		return this.snapshot.lxcpath.fromStringz.idup;
	}

	///
	~this()
	{
		if (this.snapshot !is null)
			this.snapshot.free(this.snapshot);
		this.snapshot = null;
	}
}

	///
enum FileSystemType
{
	none,
	dir,
	btrfs,
	lvm,
	overlayfs,
	zfs,
	ceph,
}

	///
FileSystemType parseFileSystemType(string type)
{
	import std.typecons:EnumMembers;
	import std.conv:to;
	import std.string:toUpper;
	foreach(entry;EnumMembers!FileSystemType)
	{
		if (entry.to!string.toUpper == type.toUpper)
			return entry;
	}
	throw new Exception("unable to parse file system type: "~ type);
}

///
struct BackingDeviceSpec
{
	///
	bdev_specs* specs;

	///
	FileSystemType fileSystemType()
	{
		return specs.fstype.fromStringz.idup.parseFileSystemType();
	}

	///
	ulong fileSystemSize()
	{
		return specs.fssize;
	}

	///
	string zfsRoot()
	{
		enforce(this.fileSystemType == FileSystemType.zfs);
		return this.specs.zfsroot.fromStringz.idup;
	}

	///
	string volumeGroup()
	{
		enforce(this.fileSystemType == FileSystemType.lvm);
		return this.specs.vg.fromStringz.idup;
	}

	///
	string logicalVolume()
	{
		enforce(this.fileSystemType == FileSystemType.lvm);
		return this.specs.lv.fromStringz.idup;		
	}

	///
	string thinPool()
	{
		enforce(this.fileSystemType == FileSystemType.lvm);
		return this.specs.thinpool.fromStringz.idup;		
	}

	///
	string directory()
	{
		enforce ((this.fileSystemType == FileSystemType.dir) || (this.fileSystemType == FileSystemType.none));
		return this.specs.dir.fromStringz.idup;
	}

	///
	string rbdImageName()
	{
		enforce(this.fileSystemType == FileSystemType.ceph);
		return this.specs.rbdname.fromStringz.idup;		

	}

	///
	string rbdPoolName()
	{
		enforce(this.fileSystemType == FileSystemType.ceph);
		return this.specs.rbdpool.fromStringz.idup;				
	}
}

///
enum MigrateCommand
{
	preDump,
	dump,
	restore,
}

///
struct MigrateOptions
{
	///
	migrate_opts* options;

	///
	string directory()
	{
		return this.options.directory.fromStringz.idup;
	}

	///
	auto ref setDirectory(string name)
	{
		this.options.directory= cast(char*) name.toStringz;
		return this;
	}

	///
	bool verbose()
	{
		return this.options.verbose;
	}

	///
	auto ref setVerbose(bool setting)
	{
		this.options.verbose = setting;
		return this;
	}

	///
	bool stop()
	{
		return this.options.stop;
	}

	///
	auto ref setStop(bool setting)
	{
		this.options.stop = setting;
		return this;
	}

	///
	string preDumpDir()
	{
		return this.options.predump_dir.fromStringz.idup;
	}

	///
	auto ref setPreDumpDir(string dir)
	{
		this.options.predump_dir = cast(char*)dir.toStringzc;
		return this;
	}

	///
	string pageServerAddress()
	{
		return this.options.pageserver_address.fromStringz.idup;
	}

	///
	auto ref setPageServerAddress(string address)
	{
		this.options.pageserver_address = cast(char*)address.toStringzc;
		return this;
	}

	///
	string pageServerPort()
	{
		return this.options.pageserver_port.fromStringz.idup;
	}

	///
	auto ref setPageServerPort(string port)
	{
		this.options.pageserver_port = cast(char*)port.toStringzc;
		return this;
	}

	///
	bool preservesINodes()
	{
		return this.options.preserves_inodes;
	}

	///
	auto ref setPreservesINodes(bool setting)
	{
		this.options.preserves_inodes = setting;
		return this;
	}

}


	///
string getGlobalConfigItem(string key)
{
	return lxc_get_global_config_item(key.toStringzc).fromStringz.idup;
}

	///
string getVersion()
{
	return lxc_get_version().fromStringz.idup;
}

	///
struct ContainersResult
{
	///
	OpStatus status = OpStatus.failure;
	///
	string[] names;
	///
	LXCContainer[] containers;
}

///
ContainersResult listDefinedContainers(string path)
{
	import std.algorithm:map;
	import std.array:array;
	ContainersResult ret;
	const(char)* lxcpath = path.toStringzc;
	char** names;
	lxc_container** cret;
	auto result = list_defined_containers(lxcpath,&names,&cret);
	if (result ==-1)
		return ret;
	if (result == 0)
	{
		ret.status = OpStatus.success;
		return ret;
	}
	ret.names = names[0..result].map!(name => name.fromStringz.idup).array;
	ret.containers = cret[0..result].map!(container => LXCContainer(container)).array;
	return ret;
}


///
ContainersResult listActiveContainers(string path)
{
	import std.algorithm:map;
	import std.array:array;
	ContainersResult ret;
	const(char*) lxcpath = path.toStringzc;
	char** names;
	lxc_container** cret;
	auto result = list_active_containers(lxcpath,&names,&cret);
	if (result ==-1)
		return ret;
	if (result == 0)
	{
		ret.status = OpStatus.success;
		return ret;
	}
	ret.names = names[0..result].map!(name => name.fromStringz.idup).array;
	ret.containers = cret[0..result].map!(container => LXCContainer(container)).array;
	return ret;
}

///
ContainersResult listAllContainers(string path)
{
	import std.algorithm:map;
	import std.array:array;
	ContainersResult ret;
	char* lxcpath = cast(char*) path.toStringzc;
	char** names;
	lxc_container** cret;
	auto result = list_all_containers(lxcpath,&names,&cret);
	if (result ==-1)
		return ret;
	if (result == 0)
	{
		ret.status = OpStatus.success;
		return ret;
	}
	ret.names = names[0..result].map!(name => name.fromStringz.idup).array;
	ret.containers = cret[0..result].map!(container => LXCContainer(container)).array;
	return ret;
}


///
OpStatus initLog(lxc_log* log)
{
	return lxc_log_init(log) ? OpStatus.success : OpStatus.failure;
}

///
void closeLog()
{
	lxc_log_close();
}

///
string[] getWaitStates()
{
	import std.algorithm:map;
	import std.array:array;
	char*[] states;
	auto numStates = lxc_get_wait_states(null);
	states.length = numStates;
	numStates = lxc_get_wait_states(cast(const(char)**) states.ptr);
	enforce(numStates == states.length);
	return states.map!(state=>state.fromStringz.idup).array;
}



///
enum CreateFlags
{
	quiet  = (1 << 0),
	maxFlags = (1 << 1),
}


///
enum AttachEnvPolicy
{
	keepEnv = 0,
	clearEnv = 1,
}

///
enum AttachFlags
{
	moveToCGroup  = LXC_ATTACH_MOVE_TO_CGROUP,
	dropCapabilities = LXC_ATTACH_DROP_CAPABILITIES,
	setPersonality = LXC_ATTACH_SET_PERSONALITY,
	lsmExec = LXC_ATTACH_LSM_EXEC,
	remountProcSys = LXC_ATTACH_REMOUNT_PROC_SYS,
	lsmNow = LXC_ATTACH_LSM_NOW,
	attachDefault = LXC_ATTACH_DEFAULT,
	attachLSM = LXC_ATTACH_LSM
}



///
struct AttachOptions
{
	///
	lxc_attach_options_t* options;

	///
	AttachFlags attachFlags()
	{
		return cast(AttachFlags) this.options.attach_flags;
	}

	///
	auto ref setAttachFlags(AttachFlags flags)
	{
		this.options.attach_flags = cast(int) flags;
		return this;
	}

	///
	string initialCwd()
	{
		return this.options.initial_cwd.fromStringz.idup;
	}
	
	///
	auto ref setInitialCwd(string cwd)
	{
		this.options.initial_cwd = cast(char*)cwd.toStringzc;
		return this;
	}

	///
	int namespaces()
	{
		return this.options.namespaces;
	}

	auto ref setNamespaces( int namespaces)
	{
		this.options.namespaces = namespaces;
		return this;
	}

	///
	c_long personality()
	{
		return this.options.personality;
	}

	///
	auto ref setPersonality(c_long personality)
	{
		this.options.personality = personality;
		return this;
	}

	///
	uid_t uid()
	{
		return this.options.uid;
	}

	///
	auto ref setUID(uid_t uid)
	{
		this.options.uid = uid;
		return this;
	}

	///
	gid_t gid()
	{
		return this.options.gid;
	}

	///
	auto ref setGID(gid_t gid)
	{
		this.options.gid = gid;
		return this;
	}

	///
	lxc_attach_env_policy_t envPolicy()
	{
		return this.options.env_policy;
	}

	///
	auto ref setEnvPolicy(lxc_attach_env_policy_t policy)
	{
		this.options.env_policy = policy;
		return this;
	}

	///
	string[] extraEnvVars()
	{
		return this.options.extra_env_vars.fromCArray;
	}

	///
	auto ref setExtraEnvVars(string[] vars)
	{
		this.options.extra_env_vars = cast(char**) vars.toCArray;
	}

	///
	string[] extraKeepEnv()
	{
		return this.options.extra_keep_env.fromCArray;
	}

	///
	auto ref setExtraKeepEnv(string[] vars)
	{
		this.options.extra_keep_env = cast(char**) vars.toCArray;
	}

	///
	auto stdIn()
	{
		return this.options.stdin_fd;
	}

	///
	auto ref setStdIn(int fd)
	{
		this.options.stdin_fd = fd;
		return this;
	}

	///
	auto stdOut()
	{
		return this.options.stdout_fd;
	}

	///
	auto ref setStdOut(int fd)
	{
		this.options.stdout_fd = fd;
		return this;
	}

	///
	auto stdErr()
	{
		return this.options.stderr_fd;
	}

	///
	auto ref setStdErr(int fd)
	{
		this.options.stderr_fd = fd;
		return this;
	}
}

///
enum LXC_ATTACH_OPTIONS_DEFAULT = lxc_attach_options_t(LXC_ATTACH_DEFAULT, -1, -1, null, -1, -1, cast(lxc_attach_env_policy_t)AttachEnvPolicy.keepEnv, null, null, 0, 1, 2);


///
struct AttachCommand
{
	///
	lxc_attach_command_t* command;

	///
	this(lxc_attach_command_t* command)
	{
		this.command = command;
	}

	///
	string program()
	{
		return this.command.program.fromStringz.idup;
	}

	///
	auto ref setProgram(string program)
	{
		this.command.program = cast(char*) program.toStringzc;
	}

	///
	string[] args()
	{
		return this.command.args.fromCArray;
	}

	///
	auto ref setArgs(string[] args)
	{
		this.command.args = cast(char**) args.toCArray;
	}
}




///
unittest
{
	import std.stdio;
	import std.string;
	import core.time:Duration,seconds;
	auto c = LXCContainer("apicontainer");

	enforce(!c.isDefined, "Container already exists");

	auto result = c.create("download", null, BackingDeviceSpec(), CreateFlags.quiet, ["-d", "ubuntu", "-r", "trusty", "-a", "i386"]);
	enforce(result == OpStatus.success,"Failed to create container rootfs");

	result = c.start(false);
	enforce(result == OpStatus.success, "Failed to start the container");

	writeln("Container state: ", c.state());
	writeln("Container PID: ", c.initPid());

	if (c.shutdown(5.seconds) != OpStatus.success)
	{
		writeln("Failed to cleanly shutdown the container, forcing.");
		enforce(c.stop() == OpStatus.success, "Failed to kill the container.");
	}

	enforce(c.destroy == OpStatus.success,"Failed to destroy the container");
}
